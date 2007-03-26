module ActiveScaffold::Config
  class Create < Form
    # global level configuration
    # --------------------------
    # the ActionLink for this action
    def self.link
      @@link
    end
    def self.link=(val)
      @@link = val
    end
    @@link = ActiveScaffold::DataStructures::ActionLink.new('new', :label => _('CREATE_NEW'), :type => :table, :security_method => :create_authorized?)

    # instance-level configuration
    # ----------------------------
    # the label= method already exists in the Form base class
    def label
      _(@label) || "#{_('CREATE_HEADER')} #{@core.label.singularize}"
    end
  end
end