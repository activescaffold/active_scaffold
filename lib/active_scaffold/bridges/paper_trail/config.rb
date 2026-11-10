# frozen_string_literal: true

module ActiveScaffold::Config
  class DeletedRecords < Base
    self.crud_type = :read

    def initialize(core_config)
      super
      @nested_link_label = self.class.nested_link_label
      @nested_link_group = self.class.nested_link_group
    end

    # the ActionLink for this action
    cattr_accessor :link, default: ActiveScaffold::DataStructures::ActionLink.new(:deleted, label: :deleted_records, type: :collection)

    # label for versions nested link
    cattr_accessor :nested_link_label, default: :changes

    # group for versions nested link
    cattr_accessor :nested_link_group, default: 'member'

    # label for versions nested link
    attr_accessor :nested_link_label

    # group for versions nested link
    attr_accessor :nested_link_group
  end
end
