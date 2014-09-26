module ActiveScaffold::Config
  class DeletedRecords < Base
    self.crud_type = :read

    def initialize(core_config)
      super
      @nested_link_label = self.class.nested_link_label
      @nested_link_group = self.class.nested_link_group
    end

    # the ActionLink for this action
    cattr_accessor :link
    @@link = ActiveScaffold::DataStructures::ActionLink.new(:deleted, :label => :deleted_records, :type => :collection)

    # label for versions nested link
    cattr_accessor :nested_link_label
    @@nested_link_label = :changes

    # group for versions nested link
    cattr_accessor :nested_link_group
    @@nested_link_group = 'member'

    # label for versions nested link
    attr_accessor :nested_link_label

    # group for versions nested link
    attr_accessor :nested_link_group
  end
end
