module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      def needs_order_expressions_in_select?
        false
      end
    end

    class PostgreSQLAdapter
      def needs_order_expressions_in_select?
        true
      end
    end
  end
end
