class File #:nodoc:
  unless File.respond_to?(:binread)
    def self.binread(file)
      File.open(file, 'rb') { |f| f.read }
    end
  end
end

ActiveScaffold::Config::Core.class_eval do
  def initialize_with_date_picker(model_id)
    initialize_without_date_picker(model_id)

    date_picker_fields = model.columns.collect { |c| {:name => c.name.to_sym, :type => c.type} if [:date, :datetime].include?(c.type) }.compact
    # check to see if file column was used on the model
    return if date_picker_fields.empty?

    # automatically set the forum_ui to a date_picker or datetime_picker
    date_picker_fields.each do |field|
      col_config = columns[field[:name]]
      col_config.form_ui = (field[:type] == :date ? :date_picker : :datetime_picker)
    end
  end

  alias_method_chain :initialize, :date_picker
end

module ActiveScaffold::Bridges::DatePicker::CastExtension
  def fallback_string_to_date_with_date_picker(string)
    Date.strptime(string, I18n.t('date.formats.default')) rescue fallback_string_to_date_without_date_picker(string)
  end
  def self.included(base)
    base.alias_method_chain :fallback_string_to_date, :date_picker
  end
end
if defined?(ActiveRecord::ConnectionAdapters::Type)
  ActiveRecord::ConnectionAdapters::Type::Date.send(:include, ActiveScaffold::Bridges::DatePicker::CastExtension)
else
  ActiveRecord::ConnectionAdapters::Column.extend ActiveScaffold::Bridges::DatePicker::CastExtension
end

ActionView::Base.class_eval do
  include ActiveScaffold::Bridges::Shared::DateBridge::SearchColumnHelpers
  alias_method :active_scaffold_search_date_picker, :active_scaffold_search_date_bridge
  alias_method :active_scaffold_search_datetime_picker, :active_scaffold_search_date_bridge
  include ActiveScaffold::Bridges::Shared::DateBridge::HumanConditionHelpers
  alias_method :active_scaffold_human_condition_date_picker, :active_scaffold_human_condition_date_bridge
  alias_method :active_scaffold_human_condition_datetime_picker, :active_scaffold_human_condition_date_bridge
  include ActiveScaffold::Bridges::DatePicker::Helper::SearchColumnHelpers
  include ActiveScaffold::Bridges::DatePicker::Helper::FormColumnHelpers
  alias_method :active_scaffold_input_datetime_picker, :active_scaffold_input_date_picker
  include ActiveScaffold::Bridges::DatePicker::Helper::DatepickerColumnHelpers
end
ActiveScaffold::Finder::ClassMethods.module_eval do
  include ActiveScaffold::Bridges::Shared::DateBridge::Finder::ClassMethods
  def datetime_conversion_for_condition_with_datepicker(column)
    if column.search_ui == :date_picker
      :to_date
    else
      datetime_conversion_for_condition_without_datepicker(column)
    end
  end
  alias_method_chain :datetime_conversion_for_condition, :datepicker

  alias_method :condition_for_date_picker_type, :condition_for_date_bridge_type
  alias_method :condition_for_datetime_picker_type, :condition_for_date_picker_type
end
ActiveScaffold::AttributeParams.module_eval do
  def datetime_conversion_for_value_with_datepicker(column)
    if column.form_ui == :date_picker
      :to_date
    else
      datetime_conversion_for_value_without_datepicker(column)
    end
  end
  alias_method_chain :datetime_conversion_for_value, :datepicker
  alias_method :column_value_for_date_picker_type, :column_value_for_datetime_type
  alias_method :column_value_for_datetime_picker_type, :column_value_for_datetime_type
end
