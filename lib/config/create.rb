module ActiveScaffold::Config
  class Create < Form
    # global level configuration
    # --------------------------
    # the ActionLink for this action
    def self.link
      @@link
    end
    @@link = ActiveScaffold::DataStructures::ActionLink.new('new', :label => _('CREATE_NEW'), :type => :table, :security_method => :create_authorized?)

    # instance-level configuration
    # ----------------------------
    # the label= method already exists in the Form base class
    def label
      @label || "#{_('CREATE')} #{@core.label.singularize}"
    end
  end
end