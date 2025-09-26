# frozen_string_literal: true

module ActiveScaffold
  module ConnectionAdapters
    module AbstractAdapter
      def needs_order_expressions_in_select?
        false
      end
    end

    module PostgreSQLAdapter
      def needs_order_expressions_in_select?
        true
      end
    end

    module SQLServerAdapter
      def needs_order_expressions_in_select?
        true
      end
    end
  end
end
