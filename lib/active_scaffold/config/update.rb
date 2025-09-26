# frozen_string_literal: true

module ActiveScaffold::Config
  class Update < ActiveScaffold::Config::Form
    self.crud_type = :update
    def initialize(core_config)
      super
      self.nested_links = self.class.nested_links
      self.add_locking_column = self.class.add_locking_column
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
    @@link = ActiveScaffold::DataStructures::ActionLink.new('edit', label: :edit, type: :member, security_method: :update_authorized?, ignore_method: :update_ignore?)

    cattr_accessor :nested_links, instance_accessor: false
    @@nested_links = false

    cattr_accessor :add_locking_column, instance_accessor: false
    @@add_locking_column = true

    columns_accessor :columns, copy: :create

    # instance-level configuration
    # ----------------------------

    attr_accessor :nested_links, :add_locking_column

    attr_writer :hide_nested_column

    def hide_nested_column
      @hide_nested_column.nil? ? true : @hide_nested_column
    end

    UserSettings.class_eval do
      user_attr :nested_links, :hide_nested_column, :add_locking_column
    end
  end
end
