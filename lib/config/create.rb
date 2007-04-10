module ActiveScaffold::Config
  class Create < Form
    self.crud_type = :create

    # global level configuration
    # --------------------------
    # the ActionLink for this action
    def self.link
      @@link
    end
    def self.link=(val)
      @@link = val
    end
    @@link = ActiveScaffold::DataStructures::ActionLink.new('new', :label => 'CREATE_NEW', :type => :table, :security_method => :create_authorized?)

    # instance-level configuration
    # ----------------------------
    # the label= method already exists in the Form base class
    def label
      @label ? _(@label) : "#{_('CREATE_HEADER')} #{@core.label.singularize}"
    end
  end
end
