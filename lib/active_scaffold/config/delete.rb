module ActiveScaffold::Config
  class Delete < Base
    self.crud_type = :delete

    def initialize(core_config)
      @core = core_config

      # start with the ActionLink defined globally
      @link = self.class.link.clone
      @action_group = self.class.action_group.clone if self.class.action_group
    end

    # global level configuration
    # --------------------------

    # the ActionLink for this action
    cattr_accessor :link
    @@link = ActiveScaffold::DataStructures::ActionLink.new('destroy', :label => :delete, :type => :member, :confirm => :are_you_sure_to_delete, :method => :delete, :crud_type => :delete, :position => false, :parameters => {:destroy_action => true}, :security_method => :delete_authorized?)

    # instance-level configuration
    # ----------------------------

    # the ActionLink for this action
    attr_accessor :link
  end
end
