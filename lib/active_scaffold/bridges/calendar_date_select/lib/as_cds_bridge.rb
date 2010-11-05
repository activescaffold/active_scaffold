module ActiveScaffold::Config
  class Core < Base

    def initialize_with_calendar_date_select(model_id)
      initialize_without_calendar_date_select(model_id)
      
      calendar_date_select_fields = self.model.columns.collect{|c| c.name.to_sym if [:date, :datetime].include?(c.type) }.compact
      # check to see if file column was used on the model
      return if calendar_date_select_fields.empty?
      
      # automatically set the forum_ui to a file column
      calendar_date_select_fields.each{|field|
        self.columns[field].form_ui = :calendar_date_select
      }
    end
    
    alias_method_chain :initialize, :calendar_date_select
    
  end
end


module ActiveScaffold
  module Bridges
    module CalendarDateSelectBridge
      # Helpers that assist with the rendering of a Form Column
      module FormColumnHelpers
        def active_scaffold_input_calendar_date_select(column, options)
          options[:class] = "#{options[:class]} text-input".strip
          calendar_date_select("record", column.name, options.merge(column.options))
        end      
      end
      
      module SearchColumnHelpers
        def active_scaffold_search_date_bridge_calendar_control(column, options, current_search, name)
          if current_search.is_a? Hash
            value = controller.class.condition_value_for_datetime(current_search[name], column.column.type == :date ? :to_date : :to_time)
          else
            value = current_search
          end
          calendar_date_select("record", column.name, 
            {:name => "#{options[:name]}[#{name}]", :value => (value ? l(value) : nil), :class => 'text-input', :id => "#{options[:id]}_#{name}", :time => column_datetime?(column) ? true : false})
        end
      end
  
      module ViewHelpers
        # Provides stylesheets to include with +stylesheet_link_tag+
        def active_scaffold_stylesheets(frontend = :default)
          super + [calendar_date_select_stylesheets]
        end
  
        # Provides stylesheets to include with +stylesheet_link_tag+
        def active_scaffold_javascripts(frontend = :default)
          super + [calendar_date_select_javascripts]
        end
      end
    end
  end
end

ActionView::Base.class_eval do
  include ActiveScaffold::Bridges::CalendarDateSelectBridge::FormColumnHelpers
  include ActiveScaffold::Bridges::Shared::DateBridge::SearchColumnHelpers
  alias_method :active_scaffold_search_calendar_date_select, :active_scaffold_search_date_bridge
  include ActiveScaffold::Bridges::Shared::DateBridge::HumanConditionHelpers
  alias_method :active_scaffold_human_condition_calendar_date_select, :active_scaffold_human_condition_date_bridge
  include ActiveScaffold::Bridges::CalendarDateSelectBridge::SearchColumnHelpers
  include ActiveScaffold::Bridges::CalendarDateSelectBridge::ViewHelpers
end

ActiveScaffold::Finder::ClassMethods.module_eval do
  include ActiveScaffold::Bridges::Shared::DateBridge::Finder::ClassMethods
  alias_method :condition_for_calendar_date_select_type, :condition_for_date_bridge_type
end
