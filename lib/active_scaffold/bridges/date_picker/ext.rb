# frozen_string_literal: true

class ActiveScaffold::Bridges::DatePicker
  module DatePickerBridge
    def initialize(model_id)
      super
      return unless ActiveScaffold::Bridges::DatePicker.default_ui

      types = %i[date datetime timestamp timestamptz]
      date_picker_fields = _columns.filter_map { |c| {name: c.name.to_sym, type: c.type} if types.include?(c.type) }
      # check to see if file column was used on the model
      return if date_picker_fields.empty?

      # automatically set the forum_ui to a date_picker or datetime_picker
      date_picker_fields.each do |field|
        col_config = columns[field[:name]]
        col_config.form_ui = (field[:type] == :date ? :date_picker : :datetime_picker)
      end
    end
  end

  module Finder
    def datetime_conversion_for_condition(column)
      if column.search_ui == :date_picker
        :to_date
      else
        super
      end
    end

    def datetime_column_date?(column)
      if %i[date_picker datetime_picker].include? column.search_ui
        column.search_ui == :date_picker
      else
        super
      end
    end

    def format_for_date(column, value, ui_name, ui_options)
      ui_options = ui_options.reverse_merge(format: :default) if ui_name == :date_picker
      super
    end

    def format_for_datetime(column, value, ui_name, ui_options)
      format = I18n.t "time.formats.#{ui_options[:format] || :picker}", default: '' if ui_name == :datetime_picker
      return super if format.blank?

      parts = Date._parse(value)
      [[:hour, '%H'], [:min, ':%M'], [:sec, ':%S']].each do |part, f|
        format.gsub!(f, '') if parts[part].blank?
      end
      format += ' %z' if parts[:offset].present? && format !~ /%z/i

      format.gsub!(/.*(?=%H)/, '') if !parts[:year] && !parts[:month] && !parts[:mday]
      [format, parts[:offset]]
    end
  end

  module AttributeParams
    def datetime_conversion_for_value(column)
      if column.form_ui == :date_picker
        :to_date
      else
        super
      end
    end
  end
end

ActiveScaffold::Config::Core.prepend ActiveScaffold::Bridges::DatePicker::DatePickerBridge
ActionView::Base.class_eval do
  alias_method :active_scaffold_search_date_picker, :active_scaffold_search_datetime
  alias_method :active_scaffold_search_datetime_picker, :active_scaffold_search_datetime
  alias_method :active_scaffold_human_condition_date_picker, :active_scaffold_human_condition_datetime
  alias_method :active_scaffold_human_condition_datetime_picker, :active_scaffold_human_condition_datetime
  include ActiveScaffold::Bridges::DatePicker::Helper::SearchColumnHelpers

  alias_method :active_scaffold_search_datetime_picker_field, :active_scaffold_search_date_picker_field
  include ActiveScaffold::Bridges::DatePicker::Helper::FormColumnHelpers

  alias_method :active_scaffold_input_datetime_picker, :active_scaffold_input_date_picker
  include ActiveScaffold::Bridges::DatePicker::Helper::DatepickerColumnHelpers
end
ActiveScaffold::Finder::ClassMethods.module_eval do
  prepend ActiveScaffold::Bridges::DatePicker::Finder

  alias_method :condition_for_date_picker_type, :condition_for_datetime
  alias_method :condition_for_datetime_picker_type, :condition_for_datetime
end
ActiveScaffold::AttributeParams.module_eval do
  prepend ActiveScaffold::Bridges::DatePicker::AttributeParams

  alias_method :column_value_for_date_picker_type, :column_value_for_datetime_type
  alias_method :column_value_for_datetime_picker_type, :column_value_for_datetime_type
end
