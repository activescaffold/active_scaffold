module ActiveScaffold::Config
  class Core < Base
    def initialize_with_unobtrusive_date_picker(model_id)
      initialize_without_unobtrusive_date_picker(model_id)
      date_fields = self.model.columns.select {|c| [:date, :datetime].include?(c.type) }
      
      # automatically set the forum_ui to a file column
      date_fields.each {|field| self.columns[field.name.to_sym].form_ui = :datepicker}
    end
    alias_method_chain :initialize, :unobtrusive_date_picker
  end
end
