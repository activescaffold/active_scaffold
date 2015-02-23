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
      @core.model.send(:include, ActiveScaffold::MarkedModel) unless @core.model < ActiveScaffold::MarkedModel
      add_mark_column
    end

    protected

    def add_mark_column
      @core.columns.add :as_marked
      @core.columns[:as_marked].label = 'M'
      @core.columns[:as_marked].list_ui = :marked
      @core.columns[:as_marked].sort = false
      @core.list.columns = [:as_marked] + @core.list.columns.names_without_auth_check unless @core.list.columns.include? :as_marked
    end
  end
end
