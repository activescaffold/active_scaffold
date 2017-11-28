module ActiveScaffold
  module Helpers
    # Helpers that assist with rendering of a human readable search statement
    module HumanConditionHelpers
      def active_scaffold_human_condition_for(column)
        return if (value = field_search_params[column.name.to_s]).nil?
        search_ui = column.search_ui
        search_ui ||= column.column.type if column.column
        if override_human_condition_column?(column)
          send(override_human_condition_column(column), value, {})
        elsif search_ui && override_human_condition?(search_ui)
          send(override_human_condition(search_ui), column, value)
        else
          logger.warn "undefined active_scaffold_human_condition method for search_ui #{search_ui} on column #{column.name}"
        end
      end

      def format_human_condition(column, opt, from = nil, to = nil)
        attribute = column.active_record_class.human_attribute_name(column.name)
        opt ||= from && to ? :between : (from ? :'>=' : :'<=')
        "#{attribute} #{as_(opt).downcase} #{from} #{to}"
      end

      def active_scaffold_human_condition_integer(column, value)
        from = format_number_value(controller.class.condition_value_for_numeric(column, value['from']), column.options) if value['from'].present?
        to = "- #{format_number_value(controller.class.condition_value_for_numeric(column, value['to']), column.options)}" if value['opt'] == 'BETWEEN'
        format_human_condition column, value['opt'].downcase, from, to
      end
      alias_method :active_scaffold_human_condition_decimal, :active_scaffold_human_condition_integer
      alias_method :active_scaffold_human_condition_float, :active_scaffold_human_condition_integer

      def active_scaffold_human_condition_string(column, value)
        opt = ActiveScaffold::Finder::STRING_COMPARATORS.key(value['opt']) || value['opt']
        to = "- #{value['to']}" if opt == 'BETWEEN'
        format_human_condition column, opt, "'#{value['from']}'", to
      end

      def active_scaffold_human_condition_date(column, value)
        conversion = column.column.type == :date ? :to_date : :to_time
        from = controller.class.condition_value_for_datetime(column, value['from'], conversion)
        from = I18n.l from if from
        to = controller.class.condition_value_for_datetime(column, value['to'], conversion) if value['opt'] == 'BETWEEN' || (value['opt'].nil? && value['to'])
        to = "- #{I18n.l to}" if to
        format_human_condition column, value['opt'], from, to
      end
      alias_method :active_scaffold_human_condition_time, :active_scaffold_human_condition_date
      alias_method :active_scaffold_human_condition_datetime, :active_scaffold_human_condition_date
      alias_method :active_scaffold_human_condition_timestamp, :active_scaffold_human_condition_date

      def active_scaffold_human_condition_boolean(column, value)
        attribute = column.active_record_class.human_attribute_name(column.name)
        label = as_(ActiveScaffold::Core.column_type_cast(value, column.column) ? :true : :false)
        as_(:boolean, :scope => :human_conditions, :column => attribute, :value => label)
      end
      alias_method :active_scaffold_human_condition_checkbox, :active_scaffold_human_condition_boolean

      def active_scaffold_human_condition_null(column, value)
        format_human_condition column, value.to_sym
      end

      def active_scaffold_human_condition_select(column, associated)
        attribute = column.active_record_class.human_attribute_name(column.name)
        associated = [associated].compact unless associated.is_a? Array
        if column.association
          method = column.options[:label_method] || :to_label
          associated = column.association.klass.where(:id => associated.map(&:to_i)).map(&method)
        elsif column.options[:options]
          associated = associated.collect do |value|
            text, val = column.options[:options].find { |text, val| (val.nil? ? text : val).to_s == value.to_s }
            value = active_scaffold_translated_option(column, text, val).first if text
            value
          end
        end
        as_(:association, :scope => :human_conditions, :column => attribute, :value => associated.join(', '))
      end
      alias_method :active_scaffold_human_condition_multi_select, :active_scaffold_human_condition_select
      alias_method :active_scaffold_human_condition_record_select, :active_scaffold_human_condition_select

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
