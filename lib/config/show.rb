module ActiveScaffold::Config
  class Show < Base
    def initialize(core_config)
      @core = core_config

      # inherit from the core's list of columns.
      self.columns = @core.columns.collect{|c| c.name}

      # start with the ActionLink defined globally
      @link = self.class.link.clone
    end

    # global level configuration
    # --------------------------
    cattr_accessor :link
    @@link = ActiveScaffold::DataStructures::ActionLink.new('show', :label => _('SHOW_BUTTON'), :type => :record, :security_method => :show_authorized?)

    # instance-level configuration
    # ----------------------------

    # the ActionLink for this action
    attr_accessor :link

    # the label for this action. used for the header.
    attr_accessor :label
    def label
      _(@label)
    end

    # provides access to the list of columns specifically meant for this action to use
    attr_reader :columns
    def columns=(val)
      @columns = ActiveScaffold::DataStructures::ActionColumns.new(*val)
    end
  end
end