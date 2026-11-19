# frozen_string_literal: true

require 'test_helper'

class MiscExtensionsTest < ActiveSupport::TestCase
  test 'date select derives prefix from a nested name' do
    base = Class.new do
      attr_reader :received_options

      private

      def datetime_selector(options, _html_options)
        @received_options = options
      end
    end
    date_select = Class.new(base) do
      prepend ActiveScaffold::DateSelectExtension
    end.new

    date_select.send(:datetime_selector, {name: 'record[birthday]'}, {})

    assert_equal 'record', date_select.received_options[:prefix]
  end

  test 'date select leaves prefix alone without a name' do
    base = Class.new do
      attr_reader :received_options

      private

      def datetime_selector(options, _html_options)
        @received_options = options
      end
    end
    date_select = Class.new(base) do
      prepend ActiveScaffold::DateSelectExtension
    end.new

    date_select.send(:datetime_selector, {prefix: 'existing'}, {})

    assert_equal 'existing', date_select.received_options[:prefix]
  end

  test 'connection adapters declare whether distinct ordering needs selected expressions' do
    abstract = Object.new.extend(ActiveScaffold::ConnectionAdapters::AbstractAdapter)
    postgresql = Object.new.extend(ActiveScaffold::ConnectionAdapters::PostgreSQLAdapter)
    sql_server = Object.new.extend(ActiveScaffold::ConnectionAdapters::SQLServerAdapter)

    assert_not abstract.needs_order_expressions_in_select?
    assert postgresql.needs_order_expressions_in_select?
    assert sql_server.needs_order_expressions_in_select?
  end
end
