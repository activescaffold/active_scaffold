module ActiveScaffold::Config
  class Update < Form
    # global level configuration
    # --------------------------
    # the ActionLink for this action
    def self.link
      @@link
    end
    @@link = ActiveScaffold::DataStructures::ActionLink.new('edit', :label => _('EDIT'), :type => :record, :security_method => :update_authorized?)

    # instance-level configuration
    # ----------------------------

    # the label= method already exists in the Form base class
    def label
      @label || "#{_('UPDATE')} #{@core.label.singularize}"
    end
  end
end