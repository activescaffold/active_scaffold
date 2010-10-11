module ActiveScaffold
  module Helpers
    # Helpers that assist with rendering of a human readable search statement
    module HumanConditionHelpers

      def active_scaffold_human_condition_for(column)
        value = field_search_params[column.name]
        search_ui = column.search_ui
        search_ui ||= column.column.type if column.column
        if override_human_condition_column?(column)
          send(override_human_condition_column(column), value, {})
        elsif search_ui and override_human_condition?(column.search_ui)
          send(override_human_condition(column.search_ui), column, value)
        else
          case search_ui
          when :integer, :decimal, :float
            "#{column.active_record_class.human_attribute_name(column.name)} #{as_(value[:opt].downcase).downcase} #{format_number_value(controller.class.condition_value_for_numeric(column, value[:from]), column.options)} #{value[:opt] == 'BETWEEN' ? '- ' + format_number_value(controller.class.condition_value_for_numeric(column, value[:to]), column.options).to_s : ''}"
          when :string
            opt = ActiveScaffold::Finder::StringComparators.index(value[:opt]) || value[:opt]
            "#{column.active_record_class.human_attribute_name(column.name)} #{as_(opt).downcase} '#{value[:from]}' #{opt == 'BETWEEN' ? '- ' + value[:to].to_s : ''}"
          when :date, :time, :datetime, :timestamp
            conversion = column.column.type == :date ? :to_date : :to_time
            from = controller.condition_value_for_datetime(value[:from], conversion)
            to = controller.condition_value_for_datetime(value[:to], conversion)
            "#{column.active_record_class.human_attribute_name(column.name)} #{as_(value[:opt])} #{I18n.l(from)} #{value[:opt] == 'BETWEEN' ? '- ' + I18n.l(to) : ''}"
          when :select, :multi_select, :record_select
            associated = value
            associated = [associated].compact unless associated.is_a? Array
            associated = column.association.klass.find(associated.map(&:to_i)).collect(&:to_label) if column.association
            "#{column.active_record_class.human_attribute_name(column.name)} = #{associated.join(', ')}"
          when :boolean, :checkbox
            label = column.column.type_cast(value) ? as_(:true) : as_(:false)
            "#{column.active_record_class.human_attribute_name(column.name)} = #{label}"
          when :null
            "#{column.active_record_class.human_attribute_name(column.name)} #{as_(value.to_sym)}"
          end
        end unless value.nil?
      end

      def override_human_condition_column?(column)
        respond_to?(override_human_condition_column(column))
      end

      # the naming convention for overriding form fields with helpers
      def override_human_condition_column(column)
        "#{column.name}_human_condition_column"
      end

      def override_human_condition?(search_ui)
        respond_to?(override_human_condition(search_ui))
      end

      # the naming convention for overriding human condition search_ui types
      def override_human_condition(search_ui)
        "active_scaffold_human_condition_#{search_ui}"
      end
    end
  end
end