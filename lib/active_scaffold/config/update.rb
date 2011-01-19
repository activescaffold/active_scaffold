module ActiveScaffold::Config
  class Update < ActiveScaffold::Config::Form
    self.crud_type = :update
    def initialize(*args)
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

    # whether we should refresh list after update or not
    cattr_accessor :refresh_list
    @@refresh_list = false

    # instance-level configuration
    # ----------------------------

    # the label= method already exists in the Form base class
    def label
      @label ? as_(@label) : as_(:update_model, :model => @core.label(:count => 1))
    end

    attr_accessor :nested_links
    cattr_accessor :nested_links
    @@nested_links = false

    attr_writer :hide_nested_column
    def hide_nested_column
      @hide_nested_column.nil? ? true : @hide_nested_column
    end

    # whether we should refresh list after update or not
    attr_accessor :refresh_list
 
  end
end
