module ActiveScaffold::Config
  class Update < ActiveScaffold::Config::Form
    self.crud_type = :update
    def initialize(core_config)
      super
      self.nested_links = self.class.nested_links
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
    @@link = ActiveScaffold::DataStructures::ActionLink.new('edit', :label => :edit, :type => :member, :security_method => :update_authorized?, :ignore_method => :update_ignore?)

    columns_accessor :columns, :copy => :create

    # instance-level configuration
    # ----------------------------

    attr_accessor :nested_links
    cattr_accessor :nested_links
    @@nested_links = false

    attr_writer :hide_nested_column
    def hide_nested_column
      @hide_nested_column.nil? ? true : @hide_nested_column
    end
  end
end
