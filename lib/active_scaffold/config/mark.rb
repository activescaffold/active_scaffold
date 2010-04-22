module ActiveScaffold::Config
  class Mark < Base
    self.crud_type = :read
    
    def initialize(core_config)
      @core = core_config
      @core.model.send(:include, ActiveScaffold::MarkedModel) unless @core.model.ancestors.include?(ActiveScaffold::MarkedModel)
      add_mark_column
    end
    
    protected
    
    def add_mark_column
      @core.columns.add :marked
      @core.columns[:marked].label = 'M'
      @core.columns[:marked].form_ui = :checkbox
      @core.columns[:marked].inplace_edit = true
      @core.columns[:marked].sort = false
      @core.list.columns = [:marked] + @core.list.columns.names unless @core.list.columns.include? :marked 
    end
  end
end
