# frozen_string_literal: true

module ActiveScaffold::Config
  class Delete < Base
    self.crud_type = :delete

    def initialize(core_config)
      super
      @refresh_list = self.class.refresh_list
    end

    # global level configuration
    # --------------------------

    # the ActionLink for this action
    cattr_accessor :link, instance_accessor: false
    @@link = ActiveScaffold::DataStructures::ActionLink.new(
      'destroy',
      label:           :delete,
      type:            :member,
      method:          :delete,
      crud_type:       :delete,
      confirm:         :are_you_sure_to_delete,
      position:        false,
      parameters:      {destroy_action: true},
      security_method: :delete_authorized?,
      ignore_method:   :delete_ignore?
    )

    # whether we should refresh list after destroy or not
    cattr_accessor :refresh_list, instance_accessor: false
    @@refresh_list = false

    # instance-level configuration
    # ----------------------------

    # the ActionLink for this action
    attr_accessor :link

    # whether we should refresh list after destroy or not
    attr_accessor :refresh_list

    undef_method :new_user_settings
  end
end
