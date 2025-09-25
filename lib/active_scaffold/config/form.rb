module ActiveScaffold::Config
  class Form < Base
    def initialize(core_config)
      super
      @show_unauthorized_columns = self.class.show_unauthorized_columns
      @refresh_list = self.class.refresh_list
      @persistent = self.class.persistent
      @floating_footer = self.class.floating_footer
      @field_descriptions = self.class.field_descriptions

      # no global setting here because multipart should only be set for specific forms
      @multipart = false
    end

    # global level configuration
    # --------------------------
    # show value of unauthorized columns instead of skip them
    class_attribute :show_unauthorized_columns, instance_accessor: false

    # whether the form stays open after an update or not
    class_attribute :persistent, instance_accessor: false
    @@persistent = false

    # whether we should refresh list after update or not
    class_attribute :refresh_list, instance_accessor: false
    @@refresh_list = false

    # whether footer should float when form is too long to fit in the screen, so footer is always available while scrolling
    class_attribute :floating_footer, instance_accessor: false
    @@floating_footer = false

    # whether field descriptions are visible always, on hover or click (:show, :hover, :click, default to :show)
    class_attribute :field_descriptions, instance_accessor: false
    @@field_descriptions = :show

    # instance-level configuration
    # ----------------------------

    # show value of unauthorized columns instead of skip them
    attr_accessor :show_unauthorized_columns

    # the ActionLink for this action
    attr_accessor :link

    # the label for this Form action. used for the header.
    attr_writer :label

    # whether the form stays open after a create or not
    attr_accessor :persistent

    # whether we should refresh list after create or not
    attr_accessor :refresh_list

    # whether footer should float when form is too long to fit in the screen, so footer is always available while scrolling
    attr_accessor :floating_footer

    # whether field descriptions are visible always, on hover or click (:show, :hover, :click, default to :show)
    attr_accessor :field_descriptions

    columns_accessor :columns do
      columns.exclude :created_on, :created_at, :updated_on, :updated_at, :as_marked
      columns.exclude(*@core.columns.filter_map { |c| c.name if c.association&.polymorphic? })
    end

    # whether the form should be multipart
    attr_writer :multipart

    def multipart?
      @multipart ? true : false
    end

    UserSettings.class_eval do
      user_attr :persistent, :refresh_list, :show_unauthorized_columns, :floating_footer, :field_descriptions

      attr_writer :multipart

      def multipart?
        defined?(@multipart) ? @multipart : @conf.multipart?
      end
    end
  end
end
