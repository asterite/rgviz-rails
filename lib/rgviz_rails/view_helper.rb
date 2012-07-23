module Rgviz
  module ViewHelper
    def rgviz(options = {})
      def get_package(name)
        down = name.downcase
        case down
        when 'areachart', 'barchart', 'bubblechart', 'candlestickchart',
          'columnchart', 'combochart', 'linechart', 'piechart',
          'scatterchart', 'steppedareachart' then 'corechart'
        else down
        end
      end

      options = options.with_indifferent_access

      id = options[:id]
      kind = options[:kind]
      url = options[:url]
      query = options[:query] || ''
      events = options[:events] || {}
      html = options[:html] || {}
      hidden = options[:hidden]
      extensions = options[:extensions]
      conditions = options[:conditions]
      virtual_columns = options[:virtual_columns]
      package = options[:package]

      rgviz_events, google_events = events.partition{|x| x[0].to_s.start_with? 'rgviz'}
      rgviz_events = rgviz_events.inject(Hash.new){|h, y| h[y[0]] = y[1]; h}
      rgviz_events = rgviz_events.with_indifferent_access

      html_prefix = (options[:html_prefix] || 'html').to_s
      js_prefix = (options[:js_prefix] || 'js').to_s
      param_prefix = (options[:param_prefix] || 'param').to_s

      html_prefix += '_'
      js_prefix += '_'
      param_prefix += '_'

      debug = options[:debug]
      opts = options[:options] || {}
      opts[:width] = 640 unless opts[:width]
      opts[:height] = 480 unless opts[:height]

      params = []
      uses_rgviz_get_value = false
      uses_rgviz_append = false

      visitor = MagicNamesVisitor.new(html_prefix, js_prefix, param_prefix)

      opts.each do |key, value|
        next unless value.kind_of?(String)

        source = visitor.get_source(value, false)
        next unless source[:source]

        case source[:source]
        when :html
          s = "rgviz_get_value('#{source[:id]}')"
          def s.encode_json(options = {})
            self
          end
          opts[key] = s
          uses_rgviz_get_value = true
        when :js
          s = "#{source[:id]}()"
          def s.encode_json(options = {})
            self
          end
          opts[key] = s
        when :param
          s = "param_#{source[:id]}"
          def s.encode_json(options = {})
            self
          end
          opts[key] = s
          params << source[:id].to_i unless params.include?(source[:id])
        end
      end

      opts = opts.to_json

      raise "Must specify an :id" unless id
      raise "Must specify a :kind" unless kind
      raise "Must specify a :url" unless url

      custom_executor = (url.is_a?(Class) and url < ActiveRecord::Base) || url.respond_to?(:execute) || url.is_a?(Rgviz::Table) || url.is_a?(Array)
      url = url_for url unless custom_executor

      # Parse the query
      query = RgvizRails::Parser.parse query, :extensions => extensions

      # And replace the html_ and javascript_ magic names
      query.accept visitor
      query_builder = visitor.query_builder
      query_builder_var = visitor.query_builder_var

      uses_rgviz_get_value |= visitor.uses_rgviz_get_value?
      uses_rgviz_append |= visitor.uses_rgviz_append?

      visitor.params.each{|p| params << p unless params.include?(p)}
      params = params.sort!.map{|i| "param_#{i}"}

      out = ''

      # Output the google jsapi tag the first time
      @first_time ||= 1
      if @first_time == 1
        out << "<script type=\"text/javascript\" src=\"http://www.google.com/jsapi\"></script>\n"
      end
      # Now the real script
      out << "<script type=\"text/javascript\">\n"

      # Define a function to get the value of an html element
      if uses_rgviz_get_value && !@defined_rgviz_get_value
        out << "function rgviz_get_value(id) {\n"
          out << "var e = document.getElementById(id);\n"
          out << "var n = e.tagName.toLowerCase();\n"
          out << "var s = null;\n"
          out << "if (n == 'select' && e.multiple) {\n"
            out << "var s = [];\n"
            out << "var o = e.options;\n"
            out << "for(var i = 0; i < o.length; i++)\n"
              out << "if (o[i].selected) s.push(o[i].value);\n"
          out << "} else if (n == 'input' && e.type.toLowerCase() == 'checkbox') {\n"
            out << "s = [e.checked];\n"
          out << "} else {\n"
            out << "s = [e.value];\n"
          out << "}\n"
          out << "return s;\n"
        out << "}\n"
        @defined_rgviz_get_value = true
      end

      # Define a function to append the value of a magic something
      if uses_rgviz_append && !@defined_rgviz_append
        out << "function rgviz_append(s, b, a) {\n"
          out << "var q = '';\n"
          out << "if (s.length == 0) {\n"
            out << "q += '1 = 2';\n"
          out << "} else if (s.length == 1 && s[0] == 'rgviz_all') {\n"
            out << "q += '1 = 1';\n"
          out << "} else {\n"
            out << "if (s.length > 1) q += '(';\n"
            out << "for(var i = 0; i < s.length; i++) {\n"
              out << "if (i > 0) q += ' or ';\n"
              out << "q += b + s[i] + a;\n"
            out << "}";
            out << "if (s.length > 1) q += ')';\n"
          out << "}\n"
          out << "return q;\n"
        out << "}\n"
        @defined_rgviz_append = true
      end

      if !options.has_key?(:load_package) || options[:load_package]
        # Load visualizations and the package, if not already loaded
        package ||= get_package(kind)

        @packages ||= []
        unless @packages.include?(package)
          out << "google.load(\"visualization\", \"1\", {'packages':['#{package}']});\n"
          @packages << package
        end
      end

      callback = "rgviz_draw_#{id}"

      # Set the callback if the function doesn't have params and if the
      # user didn't request to hide the visualization
      if !hidden && params.empty?
        out << "google.setOnLoadCallback(#{callback});\n"
      end

      # Define the visualization var and data
      out << "var rgviz_#{id} = null;\n"
      out << "var rgviz_#{id}_data = null;\n"

      # And define the callback
      out << "function #{callback}(#{params.join(', ')}) {\n"
      out << "  #{rgviz_events[:rgviz_start]}('#{id}');\n" if rgviz_events[:rgviz_start]
      unless custom_executor
        out << "  var query = new google.visualization.Query('#{url}');\n"
        out << "  #{query_builder}\n"
        out << "  alert(#{query_builder_var});\n" if debug
        out << "  query.setQuery(#{query_builder_var});\n"
        out << "  query.send(function(response) {\n"
      end
      out << "    rgviz_#{id} = new google.visualization.#{kind}(document.getElementById('#{id}'));\n"
      google_events.each do |name, handler|
        out << "    google.visualization.events.addListener(rgviz_#{id}, '#{name}', #{handler});\n"
      end

      if custom_executor
        if url.is_a?(Array)
          out << "    rgviz_#{id}_data = google.visualization.arrayToDataTable(#{url.to_json});\n"
        else
          executor_options = {}
          executor_options[:conditions] = conditions if conditions
          executor_options[:extensions] = extensions if extensions
          executor_options[:virtual_columns] = virtual_columns if virtual_columns

          table = if url.is_a?(Class) and url < ActiveRecord::Base
                    Rgviz::Executor.new(url).execute(query, executor_options)
                  elsif url.respond_to?(:execute)
                    url.execute(query, executor_options)
                  else
                    url
                  end
          out << "    rgviz_#{id}_data = new google.visualization.DataTable(#{table.to_json});\n"
        end
      else
        out << "    rgviz_#{id}_data = response.getDataTable();\n"
      end
      out << "    #{rgviz_events[:rgviz_before_draw]}(rgviz_#{id}, rgviz_#{id}_data);\n" if rgviz_events[:rgviz_before_draw]
      out << "    rgviz_#{id}_options = #{opts};\n"
      out << "    rgviz_#{id}.draw(rgviz_#{id}_data, rgviz_#{id}_options);\n"
      out << "    #{rgviz_events[:rgviz_end]}('#{id}');\n" if rgviz_events[:rgviz_end]
      unless custom_executor
        out << "});\n"
      end
      out << "}\n"

      out << "</script>\n"

      # Write the div
      out << "<div id=\"#{id}\""
      html.each do |key, value|
        out << " #{key}=\"#{h value}\""
      end
      out << "></div>\n"

      @first_time = 0


      if Rails::VERSION::MAJOR == 2
        out
      else
        raw out
      end
    end

    module_function :rgviz
  end

  class MagicNamesVisitor < Visitor
    def initialize(html_prefix, js_prefix, param_prefix)
      @html_prefix = html_prefix
      @js_prefix = js_prefix
      @param_prefix = param_prefix
      @s = ''
      @params = []
    end

    def query_builder
      @s.strip
    end

    def query_builder_var
      'q'
    end

    def params
      @params
    end

    def uses_rgviz_get_value?
      @uses_rgviz_get_value
    end

    def uses_rgviz_append?
      @uses_rgviz_append
    end

    def visit_query(node)
      @s << "var q = '"
      if node.select && node.select.columns && node.select.columns.length > 0
        node.select.accept self
      else
        @s << 'select * '
      end
      node.where.accept self if node.where
      node.group_by.accept self if node.group_by
      node.pivot.accept self if node.pivot
      node.order_by.accept self if node.order_by
      @s << "limit #{node.limit} " if node.limit
      @s << "offset #{node.offset} " if node.offset
      if node.labels
        @s << "label "
        node.labels.each_with_index do |l, i|
          @s << ', ' if i > 0
          l.accept self
        end
      end
      if node.formats
        @s << "format "
        node.formats.each_with_index do |f, i|
          @s << ', ' if i > 0
          f.accept self
        end
      end
      if node.options
        @s << "options "
        @s << "no_values " if node.options.no_values
        @s << "no_format " if node.options.no_format
      end
      @s << "';\n"
      false
    end

    def visit_select(node)
      @s << "select ";
      print_columns node
      @s << " "
      false
    end

    def visit_where(node)
      @s << "where "
      node.expression.accept self
      @s << " "
      false
    end

    def visit_group_by(node)
      @s << "group by "
      print_columns node
      @s << " "
      false
    end

    def visit_pivot(node)
      @s << "pivot "
      print_columns node
      @s << " "
      false
    end

    def visit_order_by(node)
      @s << "order by "
      node.sorts.each_with_index do |s, i|
        @s << ', ' if i > 0
        s.column.accept self
        @s << ' '
        @s << s.order.to_s
      end
      @s << " "
      false
    end

    def visit_label(node)
      node.column.accept self
      @s << ' '
      if node.label.include?("'")
        val = node.label.gsub("'", "\\'")
        @s << "\"#{val}\""
      else
        @s << "\\'#{node.label}\\'"
      end
      false
    end

    def visit_format(node)
      node.column.accept self
      @s << ' '
      if node.pattern.include?("'")
        @s << "\"#{node.pattern}\""
      else
        @s << "\\'#{node.pattern}\\'"
      end
      false
    end

    def visit_logical_expression(node)
      @s += "("
      node.operands.each_with_index do |operand, i|
        @s += " #{node.operator} " if i > 0
        operand.accept self
      end
      @s += ")"
      false
    end

    def visit_binary_expression(node)
      if node.operator == BinaryExpression::Eq
        source = has_magic_name?(node.right)
        if source
          @s << "';\n"
          case source[:source]
          when :html
            @s << "var s = rgviz_get_value('#{source[:id]}');\n"
            append_selections node, source

            @uses_rgviz_get_value = true
          when :js
            @s << "var s = #{source[:id]}();\n"
            @s << "if (typeof(s) != 'object') s = [s];\n"
            append_selections node, source
          when :param
            @s << "var s = param_#{source[:id]};\n"
            @s << "if (typeof(s) != 'object') s = [s];\n"
            append_selections node, source
            @params << source[:id].to_i unless @params.include?(source[:id])
          end
          @s << "q += '"
          return false
        end
      end
      node.left.accept self
      @s << " #{node.operator} "
      node.right.accept self
      false
    end

    def visit_unary_expression(node)
      if node.operator == UnaryExpression::Not
        @s << "not "
        node.operand.accept self
      else
        node.operand.accept self
        @s << " #{node.operator}"
      end
      false
    end

    def visit_id_column(node)
      source = get_source node.name
      case source[:source]
      when nil
        @s << "`#{node.name}`"
      when :html
        append_before_source_type source[:type]
        @s << " + rgviz_get_value('#{source[:id]}') + "
        append_after_source_type source[:type]

        @uses_rgviz_get_value = true
      when :js
        append_before_source_type source[:type]
        @s << " + #{source[:id]}() + "
        append_after_source_type source[:type]
      when :param
        append_before_source_type source[:type]
        @s << " + param_#{source[:id]} + "
        append_after_source_type source[:type]
        @params << source[:id].to_i unless @params.include?(source[:id])
      end
    end

    def visit_number_column(node)
      @s << node.value.to_s
    end

    def visit_string_column(node)
      value = node.value.gsub('"', '\"')
      @s << "\"#{value}\""
    end

    def visit_boolean_column(node)
      @s << node.value.to_s
    end

    def visit_date_column(node)
      @s << "date \"#{node.value.to_s}\""
    end

    def visit_date_time_column(node)
      @s << "date \"#{node.value.strftime('%Y-%m-%d %H:%M:%S')}\""
    end

    def visit_time_of_day_column(node)
      @s << "date \"#{node.value.strftime('%H:%M:%S')}\""
    end

    def visit_scalar_function_column(node)
      case node.function
      when ScalarFunctionColumn::Sum, ScalarFunctionColumn::Difference,
           ScalarFunctionColumn::Product, ScalarFunctionColumn::Quotient
        node.arguments[0].accept self
        @s << " #{node.function} "
        node.arguments[1].accept self
      else
        @s << "#{node.function}("
        node.arguments.each_with_index do |a, i|
          @s << ', ' if i > 0
          a.accept self
        end
        @s << ")"
      end
      false
    end

    def visit_aggregate_column(node)
      @s << "#{node.function}("
      node.argument.accept self
      @s << ")"
      false
    end

    def print_columns(node)
      node.columns.each_with_index do |c, i|
        @s << ', ' if i > 0
        c.accept self
      end
    end

    def get_source(name, include_type = true)
      if name.start_with?(@html_prefix)
        if include_type
          get_source_type :html, name[@html_prefix.length .. -1]
        else
          {:source => :html, :id => name[@html_prefix.length .. -1]}
        end
      elsif name.start_with?(@js_prefix)
        if include_type
          get_source_type :js, name[@js_prefix.length .. -1]
        else
          {:source => :js, :id => name[@js_prefix.length .. -1]}
        end
      elsif name.start_with?(@param_prefix)
        if include_type
          get_source_type :param, name[@param_prefix.length .. -1]
        else
          {:source => :param, :id => name[@param_prefix.length .. -1]}
        end
      else
        {}
      end
    end

    def get_source_type(source, name)
      if name.start_with?('number_')
        {:source => source, :id => name[7 .. -1], :type => :number}
      elsif name.start_with?('string_')
        {:source => source, :id => name[7 .. -1], :type => :string}
      elsif name.start_with?('date_')
        {:source => source, :id => name[5 .. -1], :type => :date}
      elsif name.start_with?('datetime_')
        {:source => source, :id => name[9 .. -1], :type => :datetime}
      elsif name.start_with?('timeofday_')
        {:source => source, :id => name[10 .. -1], :type => :timeofday}
      else
        {:source => source, :id => name, :type => :string}
      end
    end

    def append_before_source_type(type)
      case type
      when :number
        return
      when :string
        @s << "\"'"
      when :date
        @s << "date \"'"
      when :datetime
        @s << "datetime \"'"
      when :timeofday
        @s << "timeofday \"'"
      end
    end

    def append_after_source_type(type)
      case type
      when :number
        return
      else
        @s << "'\""
      end
    end

    def append_selections(node, source)
      @s << "q += rgviz_append(s, '";
      node.left.accept self
      @s << " #{node.operator} "
      append_before_source_type source[:type]
      @s << ", "
      append_after_source_type source[:type]
      @s << "');\n"
      @uses_rgviz_append = true
    end

    def has_magic_name?(node)
      return false unless node.kind_of?(IdColumn)
      source = get_source node.name
      return false unless source[:source]
      return source
    end
  end
end
