class File #:nodoc:
  unless File.respond_to?(:binread)
    def self.binread(file)
      File.open(file, 'rb', &:read)
    end
  end
end

class ActiveScaffold::Bridges::DatePicker
  module DatePickerBridge
    def initialize(model_id)
      super
      return unless ActiveScaffold::Bridges::DatePicker.default_ui

      date_picker_fields = _columns.collect { |c| {:name => c.name.to_sym, :type => c.type} if %i[date datetime].include?(c.type) }.compact
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

    def format_for_date(column, value, format_name = column.options[:format])
      super column, value, format_name || (:default if column.search_ui == :date_picker)
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

ActiveScaffold::Config::Core.send :prepend, ActiveScaffold::Bridges::DatePicker::DatePickerBridge
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
