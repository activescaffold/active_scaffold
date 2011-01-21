module ActiveScaffold::Config
  class Delete < Base
    self.crud_type = :delete

    def initialize(core_config)
      @core = core_config

      # start with the ActionLink defined globally
      @link = self.class.link.clone
      @action_group = self.class.action_group.clone if self.class.action_group
      self.refresh_list = self.class.refresh_list
    end

    # global level configuration
    # --------------------------

    # the ActionLink for this action
    cattr_accessor :link
    @@link = ActiveScaffold::DataStructures::ActionLink.new('destroy', :label => :delete, :type => :member, :confirm => :are_you_sure_to_delete, :method => :delete, :crud_type => :delete, :position => false, :parameters => {:destroy_action => true}, :security_method => :delete_authorized?)

    # whether we should refresh list after destroy or not
    cattr_accessor :refresh_list
    @@refresh_list = false

    # instance-level configuration
    # ----------------------------

    # the ActionLink for this action
    attr_accessor :link

    # whether we should refresh list after destroy or not
    attr_accessor :refresh_list
  end
end
