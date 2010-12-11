module Rgviz
  class MySqlAdapter
    def accept_scalar_function_column(node, visitor)
      case node.function
      when ScalarFunctionColumn::Year
        visitor << "year("
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Month
        visitor << "month("
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Day
        visitor << "day("
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Hour
        visitor << "hour("
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Minute
        visitor << "minute("
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Second
        visitor << "second("
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Millisecond
        raise NotSupported.new("The millisecond function is not supported")
      when ScalarFunctionColumn::Quarter
        visitor << "quarter("
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::DayOfWeek
        visitor << "dayofweek("
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Now
        visitor << "now()"
      when ScalarFunctionColumn::DateDiff
        visitor << "datediff("
        node.arguments[0].accept visitor
        visitor << ","
        node.arguments[1].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::ToDate
        visitor << "date_format("
        node.arguments[0].accept visitor
        visitor << ", '%Y-%m-%d')"
      when ScalarFunctionColumn::Upper
        visitor << "upper("
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Lower
        visitor << "lower("
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Concat
        visitor << "concat("
        node.arguments.each_with_index do |arg, i|
          visitor << ", " if i > 0
          arg.accept visitor
        end
        visitor << ")"
      end
    end
  end
end
