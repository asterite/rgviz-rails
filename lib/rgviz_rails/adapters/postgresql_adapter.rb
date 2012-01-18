module Rgviz
  class PostgreSqlAdapter
    def accept_scalar_function_column(node, visitor)
      case node.function
      when ScalarFunctionColumn::Year
        visitor << "date_part('year',"
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Month
        visitor << "date_part('month',"
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Day
        visitor << "date_part('day',"
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Hour
        visitor << "date_part('hour',"
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Minute
        visitor << "date_part('minute',"
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Second
        visitor << "date_part('second',"
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Millisecond
        visitor << "date_part('milliseconds',"
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Quarter
        visitor << "date_part('quarter',"
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::DayOfWeek
        visitor << "1 + date_part('dow',"
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Now
        visitor << "now()"
      when ScalarFunctionColumn::DateDiff
        visitor << "(date "
        node.arguments[0].accept visitor
        visitor << " - date "
        node.arguments[1].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::ToDate
        visitor << "to_char("
        arg = node.arguments[0]
        if arg.kind_of?(StringColumn) || arg.kind_of?(DateColumn) || arg.kind_of?(DateTimeColumn) || arg.kind_of?(TimeOfDayColumn)
          visitor << "date "
        end
        arg.accept visitor
        visitor << ", 'yyyy-mm-dd')"
      when ScalarFunctionColumn::Upper
        visitor << "upper("
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Lower
        visitor << "lower("
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Concat
        visitor << "("
        node.arguments.each_with_index do |arg, i|
          visitor << " || " if i > 0
          arg.accept visitor
        end
        visitor << ")"
      end
    end

    def visit_date_column(node, visitor)
      visitor << "#{visitor.escaped_string(node.value.strftime("%Y-%m-%d"))}"
    end

    def visit_date_time_column(node, visitor)
      visitor << "#{visitor.escaped_string(node.value.strftime("%Y-%m-%d %H:%M:%S"))}"
    end

    def visit_time_of_day_column(node, visitor)
      visitor << "#{visitor.escaped_string(node.value.strftime("%H:%M:%S"))}"
    end
  end
end
