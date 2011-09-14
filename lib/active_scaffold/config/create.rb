module ActiveScaffold::Config
  class Create < ActiveScaffold::Config::Form
    self.crud_type = :create
    def initialize(core_config)
      super
      @label = :create_model
      self.persistent = self.class.persistent
      self.action_after_create = self.class.action_after_create
      self.refresh_list = self.class.refresh_list
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

    # whether the form stays open after a create or not
    cattr_accessor :persistent
    @@persistent = false

    # whether update form is opened after a create or not
    cattr_accessor :action_after_create
    @@action_after_create = nil

    # whether we should refresh list after create or not
    cattr_accessor :refresh_list
    @@refresh_list = false

    # whether the form stays open after a create or not
    attr_accessor :persistent

    # whether the form stays open after a create or not
    attr_accessor :action_after_create

    # whether we should refresh list after create or not
    attr_accessor :refresh_list
  end
end
