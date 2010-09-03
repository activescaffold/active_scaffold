ActiveScaffold::Config::Core.class_eval do
  def initialize_with_date_picker(model_id)
    initialize_without_date_picker(model_id)
    
    date_picker_fields = self.model.columns.collect{|c| {:name => c.name.to_sym, :type => c.type} if [:date, :datetime].include?(c.type) }.compact
    # check to see if file column was used on the model
    return if date_picker_fields.empty?
    
    # automatically set the forum_ui to a file column
    date_picker_fields.each{|field|
      col_config = self.columns[field[:name]] 
      form_ui = (field[:type] == :date ? :date_picker : :datetime_picker)
      
      col_config.form_ui = form_ui
      if col_config.options[:class]
        col_config.options[:class] += " #{form_ui.to_s} text-input"
      else
        col_config.options[:class] = "#{form_ui.to_s} text-input"
      end
    }
  end
  
  alias_method_chain :initialize, :date_picker
end


module ActiveScaffold
  module Bridges
    module DatePickerBridge
      module SearchColumnHelpers
        def active_scaffold_search_date_bridge_calendar_control(column, options, current_search, name)
          options = column.options.merge(options).except!(:include_blank, :discard_time, :discard_date, :value)
          options[:class] << " #{column.options[:class]}" if column.options[:class]
          text_field_tag("#{options[:name]}[#{name}]", current_search[name], options.merge(:id => "#{options[:id]}_#{name}", :name => "#{options[:name]}[#{name}]"))
        end
      end
    end
  end
end

ActionView::Base.class_eval do
  include ActiveScaffold::Bridges::Shared::DateBridge::SearchColumnHelpers
  alias_method :active_scaffold_search_datetime, :active_scaffold_search_date_bridge
  include ActiveScaffold::Bridges::DatePickerBridge::SearchColumnHelpers
end
ActiveScaffold::Finder::ClassMethods.module_eval do
  include ActiveScaffold::Bridges::Shared::DateBridge::Finder::ClassMethods
  alias_method :condition_for_date_picker_type, :condition_for_date_bridge_type
  alias_method :condition_for_datetime_picker_type, :condition_for_date_picker_type
end
