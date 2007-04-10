module ActiveScaffold::Config
  class Update < Form
    self.crud_type = :update

    # global level configuration
    # --------------------------
    # the ActionLink for this action
    def self.link
      @@link
    end
    def self.link=(val)
      @@link = val
    end
    @@link = ActiveScaffold::DataStructures::ActionLink.new('edit', :label => 'EDIT_BUTTON', :type => :record, :security_method => :update_authorized?)

    # instance-level configuration
    # ----------------------------

    # the label= method already exists in the Form base class
    def label
      @label ? _(@label) : "#{_('UPDATE_HEADER')} #{@core.label.singularize}"
    end
  end
end
