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
    
    date_picker_fields = self.model.columns.collect{|c| {:name => c.name.to_sym, :type => c.type} if [:date, :datetime].include?(c.type) }.compact
    # check to see if file column was used on the model
    return if date_picker_fields.empty?
    
    # automatically set the forum_ui to a date_picker or datetime_picker
    date_picker_fields.each{|field|
      col_config = self.columns[field[:name]] 
      col_config.form_ui = (field[:type] == :date ? :date_picker : :datetime_picker)
    }
  end
  
  alias_method_chain :initialize, :date_picker
end

ActiveRecord::ConnectionAdapters::Column.class_eval do
  class << self
    def fallback_string_to_date_with_date_picker(string)
      Date.strptime(string, I18n.t('date.formats.default')) rescue fallback_string_to_date_without_date_picker(string)
    end
    alias_method_chain :fallback_string_to_date, :date_picker
  end
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
  def datetime_conversion_for_condition(column)
    if column.search_ui == :date_picker
      :to_date
    else
      super
    end
  end
  alias_method :condition_for_date_picker_type, :condition_for_date_bridge_type
  alias_method :condition_for_datetime_picker_type, :condition_for_date_picker_type
end
