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
        def active_scaffold_search_datetime(column, options)
          opt_value, from_value, to_value = field_search_params_range_values(column)
          options = column.options.merge(options).except!(:include_blank, :discard_time, :discard_date)
          options[:class] << " #{column.options[:class]}" if column.options[:class]
          html = []
          html << text_field_tag("#{options[:name]}[from]", from_value, active_scaffold_input_text_options(options.merge(:id => "#{options[:id]}_from", :name => "#{options[:name]}[from]")))
          html << text_field_tag("#{options[:name]}[to]", to_value, active_scaffold_input_text_options(options.merge(:id => "#{options[:id]}_to", :name => "#{options[:name]}[to]")))
          (html * ' - ').html_safe
        end
      end
  
      module Finder
        module ClassMethods
          def condition_for_date_picker_type(column, value, like_pattern)
            conversion = column.column.type == :date ? 'to_date' : 'to_time'
            from_value, to_value = ['from', 'to'].collect do |field|
              Time.zone.parse(value[field]) rescue nil
            end
  
            if from_value.nil? and to_value.nil?
              nil
            elsif !from_value
              ["#{column.search_sql} <= ?", to_value.send(conversion).to_s(:db)]
            elsif !to_value
              ["#{column.search_sql} >= ?", from_value.send(conversion).to_s(:db)]
            else
              ["#{column.search_sql} BETWEEN ? AND ?", from_value.send(conversion).to_s(:db), to_value.send(conversion).to_s(:db)]
            end
          end
          alias_method :condition_for_datetime_picker_type, :condition_for_date_picker_type
        end
      end
    end
  end
end

ActionView::Base.class_eval do
  include ActiveScaffold::Bridges::DatePickerBridge::SearchColumnHelpers
end
ActiveScaffold::Finder::ClassMethods.module_eval do
  include ActiveScaffold::Bridges::DatePickerBridge::Finder::ClassMethods
end
