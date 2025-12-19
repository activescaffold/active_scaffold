module ActiveScaffold::Config
  class FieldSearch < Base
    self.crud_type = :read
    NO_COLUMNS = [].freeze

    def initialize(core_config)
      super
      @text_search = self.class.text_search
      @human_conditions = self.class.human_conditions
      @floating_footer = self.class.floating_footer
      @reset_form = self.class.reset_form
      @update_columns = self.class.update_columns
    end

    # global level configuration
    # --------------------------
    # the ActionLink for this action
    cattr_reader :link, instance_accessor: false
    @@link = ActiveScaffold::DataStructures::ActionLink.new('show_search', label: :search, type: :collection, security_method: :search_authorized?, ignore_method: :field_search_ignore?)

    # A flag for how the search should do full-text searching in the database:
    # * :full: LIKE %?%
    # * :start: LIKE ?%
    # * :end: LIKE %?
    # * false: LIKE ?
    # Default is :full
    cattr_accessor :text_search, instance_accessor: false
    @@text_search = :full

    # human conditions
    # instead of just filtered you may show the user a humanized search condition statment
    cattr_accessor :human_conditions, instance_accessor: false
    @@human_conditions = false

    # whether footer should float when form is too long to fit in the screen, so footer is always available while scrolling
    class_attribute :floating_footer, instance_accessor: false
    @@floating_footer = false

    cattr_accessor :reset_form, instance_accessor: false

    # whether refresh columns defined in update_columns when a column is changed, as create and update forms do
    cattr_accessor :update_columns

    # instance-level configuration
    # ----------------------------

    columns_accessor :columns do
      columns.exclude @core.columns.active_record_class.locking_column.to_sym
    end

    # A flag for how the search should do full-text searching in the database:
    # * :full: LIKE %?%
    # * :start: LIKE ?%
    # * :end: LIKE %?
    # * false: LIKE ?
    # Default is :full
    attr_accessor :text_search

    # the ActionLink for this action
    attr_accessor :link

    # rarely searched columns may be placed in a hidden subgroup
    def optional_columns=(optionals)
      @optional_columns = Array(optionals)
    end

    def optional_columns
      return @optional_columns || NO_COLUMNS if frozen?

      @optional_columns ||= NO_COLUMNS.dup
    end

    # add array of columns as options for group by to get aggregated listings
    attr_accessor :group_options

    # columns to display on aggregated listing
    attr_accessor :grouped_columns

    # default search params
    # default_params = {title: {"from"=>"test", "to"=>"", "opt"=>"%?%"}}
    attr_accessor :default_params

    # human conditions
    # instead of just filtered you may show the user a humanized search condition statment
    attr_accessor :human_conditions

    # whether footer should float when form is too long to fit in the screen, so footer is always available while scrolling
    attr_accessor :floating_footer

    attr_accessor :reset_form

    # whether refresh columns defined in update_columns when a column is changed, as create and update forms do
    attr_accessor :update_columns

    UserSettings.class_eval do
      user_attr :optional_columns, :group_options, :grouped_columns, :human_conditions, :floating_footer, :update_columns
    end
  end
end
