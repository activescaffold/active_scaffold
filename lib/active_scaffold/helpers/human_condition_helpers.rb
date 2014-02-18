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
            "#{column.active_record_class.human_attribute_name(column.name)} #{as_(value[:opt].downcase).downcase} #{format_number_value(controller.class.condition_value_for_numeric(column, value[:from]), column.options) if value[:from].present?} #{value[:opt] == 'BETWEEN' ? '- ' + format_number_value(controller.class.condition_value_for_numeric(column, value[:to]), column.options).to_s : ''}"
          when :string
            opt = ActiveScaffold::Finder::StringComparators.index(value[:opt]) || value[:opt]
            "#{column.active_record_class.human_attribute_name(column.name)} #{as_(opt).downcase} '#{value[:from]}' #{opt == 'BETWEEN' ? '- ' + value[:to].to_s : ''}"
          when :date, :time, :datetime, :timestamp
            conversion = column.column.type == :date ? :to_date : :to_time
            from = controller.condition_value_for_datetime(column, value[:from], conversion)
            to = controller.condition_value_for_datetime(column, value[:to], conversion)
            "#{column.active_record_class.human_attribute_name(column.name)} #{as_(value[:opt])} #{I18n.l(from)} #{value[:opt] == 'BETWEEN' ? '- ' + I18n.l(to) : ''}"
          when :select, :multi_select, :record_select
            associated = value
            associated = [associated].compact unless associated.is_a? Array
            if column.association
              method = column.options[:label_method] || :to_label
              associated = column.association.klass.where(:id => associated.map(&:to_i)).collect(&method)
            elsif column.options[:options]
              associated = associated.collect do |value|
                text, val = column.options[:options].find {|text, val| (val.nil? ? text : val).to_s == value.to_s}
                value = active_scaffold_translated_option(column, text, val).first if text
                value
              end
            end
            as_(:association, :scope => :human_conditions, :column => column.active_record_class.human_attribute_name(column.name), :value => associated.join(', '))
          when :boolean, :checkbox
            label = column.column.type_cast(value) ? as_(:true) : as_(:false)
            as_(:boolean, :scope => :human_conditions, :column => column.active_record_class.human_attribute_name(column.name), :value => label)
          when :null
            "#{column.active_record_class.human_attribute_name(column.name)} #{as_(value.to_sym)}"
          end
        end unless value.nil?
      end

      # the naming convention for overriding form fields with helpers
      def override_human_condition_column(column)
        override_helper column, 'human_condition_column'
      end
      alias_method :override_human_condition_column?, :override_human_condition_column

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
