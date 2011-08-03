module ActiveScaffold::Config
  class Mark < Base
    self.crud_type = :read

    # What kind of mark all mode to use:
    # * :search: de-/mark all records using current search conditions
    # * :page: de-/mark all records on current page
    cattr_accessor :mark_all_mode
    @@mark_all_mode = :search

    attr_accessor :mark_all_mode
    
    def initialize(core_config)
      @core = core_config
      @mark_all_mode = self.class.mark_all_mode
      if core_config.actions.include?(:update)
        @core.model.send(:include, ActiveScaffold::MarkedModel) unless @core.model.ancestors.include?(ActiveScaffold::MarkedModel)
        add_mark_column
      else
        raise "Mark action requires update action in controller for model: #{core_config.model.to_s}"
      end
    end
    
    protected
    
    def add_mark_column
      @core.columns.add :marked
      @core.columns[:marked].label = 'M'
      @core.columns[:marked].form_ui = :checkbox
      @core.columns[:marked].inplace_edit = true
      @core.columns[:marked].sort = false
      @core.list.columns = [:marked] + @core.list.columns.names_without_auth_check unless @core.list.columns.include? :marked
    end
  end
end
