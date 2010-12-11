module Rgviz
  class SqliteAdapter
    def accept_scalar_function_column(node, visitor)
      case node.function
      when ScalarFunctionColumn::Year
        visitor << "strftime('%Y', "
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Month
        visitor << "strftime('%m', "
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Day
        visitor << "strftime('%d', "
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Hour
        visitor << "strftime('%H', "
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Minute
        visitor << "strftime('%M', "
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Second
        visitor << "strftime('%S', "
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Millisecond
        raise NotSupported.new("The millisecond function is not supported")
      when ScalarFunctionColumn::Quarter
        raise NotSupported.new("The quarter function is not supported")
      when ScalarFunctionColumn::DayOfWeek
        visitor << "1 + strftime('%w', "
        node.arguments[0].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::Now
        visitor << "strftime('%Y-%m-%d %H:%M:%S')"
      when ScalarFunctionColumn::DateDiff
        visitor << "julianday("
        node.arguments[0].accept visitor
        visitor << ") - julianday("
        node.arguments[1].accept visitor
        visitor << ")"
      when ScalarFunctionColumn::ToDate
        visitor << "strftime('%Y-%m-%d', "
        node.arguments[0].accept visitor
        visitor << ")"
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
  end
end
