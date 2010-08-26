module ActiveScaffold::Config
  class Create < ActiveScaffold::Config::Form
    self.crud_type = :create
    def initialize(*args)
      super
      self.persistent = self.class.persistent
      self.action_after_create = self.class.action_after_create
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
    @@link = ActiveScaffold::DataStructures::ActionLink.new('new', :label => :create_new, :type => :collection, :security_method => :create_authorized?)

    # whether the form stays open after a create or not
    cattr_accessor :persistent
    @@persistent = false

    # whether update form is opened after a create or not
    cattr_accessor :action_after_create
    @@action_after_create = nil

    # instance-level configuration
    # ----------------------------
    # the label= method already exists in the Form base class
    def label(model = nil)
      model ||= @core.label(:count => 1)
      @label ? as_(@label) : as_(:create_model, :model => model)
    end
    
    # whether the form stays open after a create or not
    attr_accessor :persistent

    # whether the form stays open after a create or not
    attr_accessor :action_after_create
  end
end
