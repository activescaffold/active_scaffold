module ActiveScaffold::Config
  class Delete < Base
    def initialize(core_config)
      @core = core_config

      # start with the ActionLink defined globally
      @link = self.class.link.clone
    end

    # global level configuration
    # --------------------------

    # the ActionLink for this action
    cattr_reader :link
    @@link = ActiveScaffold::DataStructures::ActionLink.new('destroy', :label => _('DELETE'), :type => :record, :confirm => _('ARE_YOU_SURE'), :position => false, :security_method => :delete_authorized?)

    # instance-level configuration
    # ----------------------------

    # the ActionLink for this action
    attr_reader :link
  end
end