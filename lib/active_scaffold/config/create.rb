module ActiveScaffold::Config
  class Create < Form
    self.crud_type = :create
    def initialize(*args)
      super
      self.persistent = self.class.persistent
      self.show_on_list = self.class.show_on_list
      self.edit_after_create = self.class.edit_after_create
    end

    # global level configuration
    # --------------------------
    # the ActionLink for this action
    def self.link
      @@link
    end
    def self.link=(val)
      @@link = val
    end
    @@link = ActiveScaffold::DataStructures::ActionLink.new('new', :label => 'Create New', :type => :table, :security_method => :create_authorized?)

    # whether the create form is initially displayed on list or not
    cattr_accessor :show_on_list
    @@show_on_list = false
    
    # whether the form stays open after a create or not
    cattr_accessor :persistent
    @@persistent = false

    # whether update form is opened after a create or not
    cattr_accessor :edit_after_create
    @@edit_after_create = false

    # instance-level configuration
    # ----------------------------
    # the label= method already exists in the Form base class
    def label
      @label ? as_(@label) : as_('Create %s', @core.label.singularize)
    end

    # whether the create form is initially displayed on list or not
    attr_accessor :show_on_list
    
    # whether the form stays open after a create or not
    attr_accessor :persistent

    # whether the form stays open after a create or not
    attr_accessor :edit_after_create
  end
end
