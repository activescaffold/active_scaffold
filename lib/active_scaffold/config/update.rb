module ActiveScaffold::Config
  class Update < ActiveScaffold::Config::Form
    self.crud_type = :update
    def initialize(*args)
      super
      self.nested_links = self.class.nested_links
      self.persistent = self.class.persistent
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
    @@link = ActiveScaffold::DataStructures::ActionLink.new('edit', :label => :edit, :type => :member, :security_method => :update_authorized?)

    # whether the form stays open after an update or not
    cattr_accessor :persistent
    @@persistent = false
    
    # instance-level configuration
    # ----------------------------

    # the label= method already exists in the Form base class
    def label
      @label ? as_(@label) : as_(:update_model, :model => @core.label(:count => 1))
    end

    attr_accessor :nested_links
    cattr_accessor :nested_links
    @@nested_links = false
    
    # whether the form stays open after an update or not
    attr_accessor :persistent
  end
end
