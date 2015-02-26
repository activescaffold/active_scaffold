module ActiveScaffold::Config
  class Create < ActiveScaffold::Config::Form
    self.crud_type = :create
    def initialize(core_config)
      super
      @label = :create_model
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
    @@link = ActiveScaffold::DataStructures::ActionLink.new('new', :label => :create_new, :type => :collection, :security_method => :create_authorized?, :ignore_method => :create_ignore?)

    # whether update form is opened after a create or not
    cattr_accessor :action_after_create
    @@action_after_create = nil

    # instance-level configuration
    # ----------------------------

    # whether the form stays open after a create or not
    attr_accessor :action_after_create
  end
end
