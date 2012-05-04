module ActiveScaffold::Config
  class Update < ActiveScaffold::Config::Form
    self.crud_type = :update
    def initialize(core_config)
      super
      self.nested_links = self.class.nested_links
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
    @@link = ActiveScaffold::DataStructures::ActionLink.new('edit', :label => :edit, :type => :member, :security_method => :update_authorized?)

    # whether the form stays open after an update or not
    cattr_accessor :persistent
    @@persistent = false

    # whether we should refresh list after update or not
    cattr_accessor :refresh_list
    @@refresh_list = false

    # instance-level configuration
    # ----------------------------

    attr_accessor :nested_links
    cattr_accessor :nested_links
    @@nested_links = false
    
    # whether the form stays open after an update or not
    attr_accessor :persistent

    attr_writer :hide_nested_column
    def hide_nested_column
      @hide_nested_column.nil? ? true : @hide_nested_column
    end

    # whether we should refresh list after update or not
    attr_accessor :refresh_list
 
  end
end
