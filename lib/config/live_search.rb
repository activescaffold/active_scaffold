module ActiveScaffold::Config
  class LiveSearch < Base
    def initialize(core_config)
      @core = core_config

      # inherit searchable columns from the core's list of columns
      self.columns = @core.columns.collect{|c| c.name if c.searchable? and (c.column.type == :string or c.column.type == :text)}.compact
    end
      

    # global level configuration
    # --------------------------
    # the ActionLink for this action
    cattr_accessor :link
    @@link = ActiveScaffold::DataStructures::ActionLink.new('show_search', :label => _('SEARCH'), :type => :table, :security_method => :search_authorized?)

    # instance-level configuration
    # ----------------------------

    # provides access to the list of columns specifically meant for the Search to use
    attr_reader :columns
    def columns=(val)
      @columns = ActiveScaffold::DataStructures::ActionColumns.new(*val)
    end
  end
end
