# frozen_string_literal: true

module ActiveScaffold::Config
  class Show < Base
    self.crud_type = :read
    def initialize(core_config)
      super
      self.inline_links = self.class.inline_links
    end

    # global level configuration
    # --------------------------
    cattr_accessor :link, instance_accessor: false
    @@link = ActiveScaffold::DataStructures::ActionLink.new('show', label: :show, type: :member, security_method: :show_authorized?, ignore_method: :show_ignore?)

    cattr_accessor :inline_links, instance_accessor: false
    @@inline_links = false

    # instance-level configuration
    # ----------------------------

    attr_accessor :inline_links

    # the ActionLink for this action
    attr_accessor :link
    # the label for this action. used for the header.
    attr_writer :label

    columns_accessor :columns

    UserSettings.class_eval do
      user_attr :inline_links
    end
  end
end
