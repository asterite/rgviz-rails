module Rgviz
  class Executor
    attr_reader :model_class
    attr_reader :adapter

    def initialize(model_class)
      @model_class = model_class
      @selects = []
      @joins = {}
      @labels = {}
      @formats = {}
      @pivots = {}
      @group_bys = {}
      @original_columns = []
      case ActiveRecord::Base.connection.adapter_name.downcase
      when 'sqlite'
        require File.dirname(__FILE__) + '/adapters/sqlite_adapter.rb'
        @adapter = SqliteAdapter.new
      when 'mysql', 'mysql2'
        require File.dirname(__FILE__) + '/adapters/mysql_adapter.rb'
        @adapter = MySqlAdapter.new
      when 'postgresql'
        require File.dirname(__FILE__) + '/adapters/postgresql_adapter.rb'
        @adapter = PostgreSqlAdapter.new
      end
    end

    def execute(query, options = {})
      @query = query
      @query = RgvizRails::Parser.parse(@query, options) unless @query.kind_of?(Query)

      @table = Table.new
      @extra_conditions = options[:conditions]

      process_pivot
      process_labels
      process_formats

      generate_columns
      generate_conditions
      generate_group
      generate_order

      generate_rows

      @table
    end

    def process_labels
      return unless @query.labels.present?

      @query.labels.each do |label|
        @labels[label.column.to_s] = label.label
      end
    end

    def process_formats
      return unless @query.formats.present?

      @query.formats.each do |format|
        @formats[format.column.to_s] = format.pattern
      end
    end

    def process_pivot
      if @query.pivot
        @query.pivot.columns.each do |column|
          @pivots[column.to_s] = true
        end
      end

      if @query.group_by
        @query.group_by.columns.each do |column|
          @group_bys[column.to_s] = true
        end
      end
    end

    def add_joins(joins)
      map = @joins
      joins.each do |join|
        key = join.name
        val = map[key]
        map[key] = {} unless val
        map = map[key]
      end
    end

    def generate_columns
      if @query.select && @query.select.columns.present?
        # Select the specified columns
        i = 0
        @query.select.columns.each do |col|
          col_to_s = col.to_s

          @table.cols << (Column.new :id => column_id(col, i), :type => column_type(col), :label => column_label(col_to_s))
          @selects << "(#{column_select(col)}) as c#{i}"
          @original_columns << col_to_s
          i += 1
        end
      else
        # Select all columns
        i = 0
        @model_class.send(:columns).each do |col|
          @table.cols << (Column.new :id => col.name, :type => (rails_column_type col), :label => column_label(col.name))
          @selects << "(#{ActiveRecord::Base.connection.quote_column_name(col.name)}) as c#{i}"
          @original_columns << col.name
          i += 1
        end
      end

      # Select pivot columns and group by columns
      if @query.pivot
        @max_before_pivot_columns = @original_columns.length

        @query.pivot.columns.each do |col|
          col_to_s = col.to_s

          @table.cols << (Column.new :id => column_id(col, i), :type => column_type(col), :label => column_label(col_to_s))
          @selects << "(#{column_select(col)}) as c#{i}"
          @original_columns << col_to_s
          i += 1
        end

        @max_original_columns = @original_columns.length

        if @query.group_by
          @query.group_by.columns.each do |col|
            col_to_s = col.to_s

            @table.cols << (Column.new :id => column_id(col, i), :type => column_type(col), :label => column_label(col_to_s))
            @selects << "(#{column_select(col)}) as c#{i}"
            i += 1
          end
        end
      end
    end

    def generate_conditions
      @conditions = to_string @query.where, WhereVisitor if @query.where
    end

    def generate_group
      @group = to_string @query.group_by, ColumnVisitor if @query.group_by
      pivot = to_string @query.pivot, ColumnVisitor if @query.pivot

      if pivot.present?
        if @group.present?
          @group += ',' + pivot
        else
          @group = pivot
        end
      end
    end

    def generate_order
      @order = to_string @query.order_by, OrderVisitor if @query.order_by
    end

    def generate_rows
      conditions = @conditions
      if @extra_conditions
        if conditions
          if @extra_conditions.kind_of? String
            conditions = "(#{conditions}) AND #{@extra_conditions}"
          elsif @extra_conditions.kind_of?(Array) && !@extra_conditions.empty?
            conditions = ["(#{conditions}) AND #{@extra_conditions[0]}", *@extra_conditions[1 .. -1]]
          end
        else
          conditions = @extra_conditions
        end
      end

      results = @model_class.send :all,
        :select => @selects.join(','),
        :conditions => conditions,
        :group => @group,
        :order => @order,
        :limit => @query.limit,
        :offset => @query.offset,
        :joins => @joins

      if @pivots.empty? || results.empty?
        @table.cols = @table.cols[0 ... @max_before_pivot_columns] if @pivots.present?

        # Simple, just convert the results to a table
        results.each do |result|
          row = Row.new
          @table.rows << row

          i = 0
          @table.cols.each do |col|
            hash = {}
            hash[:v] = column_value(col, result.send("c#{i}")) unless @query.options && @query.options.no_values

            format = @formats[@original_columns[i]]
            hash[:f] = format_value(col, format, hash[:v]) if format

            row.c << Cell.new(hash)
            i += 1
          end
        end
      else
        # A little more complicated...

        # This is grouping => pivot => [selections]
        fin = ActiveSupport::OrderedHash.new

        # The uniq pivot values
        uniq_pivots = []

        # Fill fin and uniq_pivots
        results.each do |result|
          # The grouping key of this result
          grouped_by = []

          # The pivots of this result
          pivots = []

          # The selections of this result
          selections = []

          # Fill grouped_by, pivots and selections, as well as uniq_pivots
          @table.cols.each_with_index do |col, i|
            val = column_value(col, result.send("c#{i}"))
            if i >= @max_original_columns || @group_bys.include?(@original_columns[i])
              grouped_by << val
            elsif @pivots.include?(@original_columns[i])
              pivots << val
            else
              selections << val
            end
          end

          uniq_pivots << pivots unless uniq_pivots.include? pivots

          # Now put all this info into fin
          fin[grouped_by] = {} unless fin[grouped_by]
          fin[grouped_by][pivots] = selections
        end

        # Sort the uniq pivots so the results will be sorted for a human
        uniq_pivots.sort!

        # Regenerate the columns info: the current info has the values
        # we needed to get the info we needed
        col_i = 0
        new_cols = []
        @original_columns.each_with_index do |original_column, i|
          break if i >= @max_original_columns

          old_col = @table.cols[i]
          if @group_bys.include?(original_column)
            old_col.id = "c#{col_i}"
            new_cols << @table.cols[i]
            col_i += 1
          elsif !@pivots.include?(original_column)
            uniq_pivots.each do |uniq_pivot|
              new_cols << (Column.new :id => "c#{col_i}", :type => old_col.type, :label => "#{uniq_pivot.join(', ')} #{old_col.label}")
              col_i += 1
            end
          end
        end

        @table.cols = new_cols

        # Create the rows
        fin.each do |key, value|
          row = Row.new
          @table.rows << row

          group_i = 0
          value_i = 0
          @original_columns.each_with_index do |original_column, i|
            if @group_bys.include?(original_column)
              hash = {}
              hash[:v] = key[group_i] unless @query.options && @query.options.no_values
              hash[:v] = 0 if hash[:v].nil? && is_count_column(@query.select.columns[i])

              format = @formats[original_column]
              hash[:f] = format_value(@table.cols[i], format, hash[:v]) if format

              row.c << (Cell.new hash)
              group_i += 1
            elsif !@pivots.include?(original_column)
              uniq_pivots.each do |uniq_pivot|
                v = value[uniq_pivot]
                v = v[value_i] if v

                hash = {}
                hash[:v] = v unless @query.options && @query.options.no_values
                hash[:v] = 0 if hash[:v].nil? && is_count_column(@query.select.columns[i])

                format = @formats[original_column]
                hash[:f] = format_value(@table.cols[i], format, hash[:v]) if format

                row.c << (Cell.new hash)
              end
              value_i += 1
            end
          end
        end
      end
    end

    def is_count_column(col)
      col.is_a?(AggregateColumn) && col.function == AggregateColumn::Count
    end

    def column_id(col, i)
      case col
      when IdColumn
        col.name
      else
        "c#{i}"
      end
    end

    def column_type(col)
      case col
      when IdColumn
        klass, rails_col, joins = Rgviz::find_rails_col @model_class, col.name
        raise "Unknown column #{col}" unless rails_col
        rails_column_type rails_col
      when NumberColumn
        :number
      when StringColumn
        :string
      when BooleanColumn
        :boolean
      when DateColumn
        :date
      when DateTimeColumn
        :datetime
      when TimeOfDayColumn
        :timeofday
      when ScalarFunctionColumn
        case col.function
        when ScalarFunctionColumn::Now
          :datetime
        when ScalarFunctionColumn::ToDate
          :date
        when ScalarFunctionColumn::Upper, ScalarFunctionColumn::Lower, ScalarFunctionColumn::Concat
          :string
        else
          :number
        end
      when AggregateColumn
        :number
      end
    end

    def column_select(col)
      to_string col, ColumnVisitor
    end

    def column_value(col, value)
      case col.type
      when :number
        i = value.to_i
        f = value.to_f
        i == f ? i : f
      when :boolean
        value == 1 || value == '1' ? true : false
      when :date
        value = Time.parse(value).to_date if value.is_a? String
        def value.as_json(options = {})
          self
        end
        def value.encode_json(*)
          month = strftime("%m").to_i - 1
          "new Date(#{strftime("%Y,#{month},%d")})"
        end
        value
      when :datetime
        value = Time.parse(value) if value.is_a? String
        def value.as_json(*)
          self
        end
        def value.encode_json(*)
          month = strftime("%m").to_i - 1
          "new Date(#{strftime("%Y,#{month},%d,%H,%M,%S")})"
        end
        value
      when :timeofday
        value = Time.parse(value) if value.is_a? String
        def value.as_json(*)
          self
        end
        def value.encode_json(*)
          "new Date(#{strftime('0,0,0,%H,%M,%S')})"
        end
        value
      else
        value.to_s
      end
    end

    def column_label(string)
      @labels[string] || string
    end

    def format_value(col, format, value)
      return nil if value.nil?

      case col.type
      when :boolean, :number, :string
        format % value
      when :date, :datetime, :timeofday
        value.strftime(format)
      end
    end

    def to_string(node, visitor_class)
      visitor = visitor_class.new self
      node.accept visitor
      visitor.string
    end

    def rails_column_type(col)
      case col.type
      when :integer, :float, :decimal
        :number
      else
        col.type
      end
    end
  end

  class ColumnVisitor < Rgviz::Visitor
    attr_reader :string

    def initialize(executor)
      @string = ''
      @executor = executor
    end

    def <<(string)
      @string += string
    end

    def visit_id_column(node)
      klass, rails_col, joins = Rgviz::find_rails_col @executor.model_class, node.name
      raise "Unknown column '#{node.name}'" unless rails_col
      @string += ActiveRecord::Base.connection.quote_column_name(klass.table_name)
      @string += '.'
      @string += ActiveRecord::Base.connection.quote_column_name(rails_col.name)

      @executor.add_joins joins
    end

    def visit_number_column(node)
      @string += node.value.to_s
    end

    def visit_string_column(node)
      @string += escaped_string(node.value)
    end

    def visit_boolean_column(node)
      @string += node.value ? '1' : '0'
    end

    def visit_date_column(node)
      @executor.adapter.visit_date_column node, self
    end

    def visit_date_time_column(node)
      @executor.adapter.visit_date_time_column node, self
    end

    def visit_time_of_day_column(node)
      @executor.adapter.visit_time_of_day_column node, self
    end

    def visit_scalar_function_column(node)
      case node.function
      when ScalarFunctionColumn::Sum, ScalarFunctionColumn::Difference,
           ScalarFunctionColumn::Product, ScalarFunctionColumn::Quotient
        @string += "("
        node.arguments[0].accept self
        @string += node.function.to_s
        node.arguments[1].accept self
        @string += ")"
      else
        @executor.adapter.accept_scalar_function_column(node, self)
      end
      false
    end

    def visit_aggregate_column(node)
      @string += node.function.to_s
      @string += '('
      node.argument.accept self
      @string += ')'
      false
    end

    def visit_group_by(node)
      node.columns.each_with_index do |c, i|
        @string += ',' if i > 0
        c.accept self
      end
      false
    end

    def visit_pivot(node)
      node.columns.each_with_index do |c, i|
        @string += ',' if i > 0
        c.accept self
      end
      false
    end

    def visit_label(node)
      false
    end

    def visit_format(node)
      false
    end

    def visit_option(node)
      false
    end

    def escaped_string(str)
      str = str.gsub("'", "''")
      "'#{str}'"
    end
  end

  class WhereVisitor < ColumnVisitor
    def visit_logical_expression(node)
      @string += "("
      node.operands.each_with_index do |operand, i|
        @string += " #{node.operator} " if i > 0
        operand.accept self
      end
      @string += ")"
      false
    end

    def visit_binary_expression(node)
      node.left.accept self
      @string += " #{node.operator} "
      node.right.accept self
      false
    end

    def visit_unary_expression(node)
      case node.operator
      when UnaryExpression::Not
        @string += 'not ('
        node.operand.accept self
        @string += ')'
      when UnaryExpression::IsNull
        node.operand.accept self
        @string += ' is null'
      when UnaryExpression::IsNotNull
        node.operand.accept self
        @string += ' is not null'
      end
      false
    end
  end

  class OrderVisitor < ColumnVisitor
    def visit_order_by(node)
      node.sorts.each_with_index do |sort, i|
        @string += ',' if i > 0
        sort.accept self
      end
      false
    end

    def visit_sort(node)
      node.column.accept self
      @string += node.order == Sort::Asc ? ' asc' : ' desc'
      false
    end
  end

  def self.find_rails_col(klass, name)
    joins = []

    while true
      col = klass.send(:columns).select{|x| x.name == name}.first
      return [klass, col, joins] if col

      before = ""
      idx = name.index('_') or raise "Unknown column #{name}"
      while idx
        before += "_" unless before.blank?
        before += "#{name[0 ... idx]}"
        name = name[idx + 1 .. -1]
        assoc = klass.send :reflect_on_association, before.to_sym
        if assoc
          klass = assoc.klass
          joins << assoc
          idx = nil
        else
          idx = name.index '_'
          raise "Unknown association #{before}" unless idx
        end
      end
    end
  end

  class NotSupported < ::Exception
  end
end
