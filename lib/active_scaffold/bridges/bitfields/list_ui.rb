# frozen_string_literal: true

module ActiveScaffold
  module Bridges
    class Bitfields
      module ListColumnHelpers
        def format_column_value(record, column, value = nil)
          if record.class.respond_to?(:bitfields) && record.class.bitfields&.include?(column.name)
            value = record.bitfield_values(column.name).select { |_, v| v }.keys
            safe_join active_scaffold_config.columns.select { |c| c.name.in? value }.map(&:label), ', '
          else
            super
          end
        end
      end
    end
  end
end
ActionView::Base.class_eval do
  include ActiveScaffold::Bridges::Bitfields::ListColumnHelpers
end
