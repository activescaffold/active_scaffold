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
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumns
      def active_scaffold_input_calendar_date_select(column, options)
        calendar_date_select("record", column.name, options)
      end      
    end
  end
end

module ActiveScaffold
  module Helpers
    module ViewHelpers

      def active_scaffold_includes_with_calendar_date_select
        active_scaffold_includes_without_calendar_date_select + 
          calendar_date_select_includes
      end
      
      alias_method_chain :active_scaffold_includes, :calendar_date_select
    end
  end
end
