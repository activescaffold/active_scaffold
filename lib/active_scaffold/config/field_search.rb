module ActiveScaffold::Config
  class FieldSearch < Base
    self.crud_type = :read

    def initialize(core_config)
      super
      @text_search = self.class.text_search
      @human_conditions = self.class.human_conditions
    end

    # global level configuration
    # --------------------------
    # the ActionLink for this action
    cattr_reader :link
    @@link = ActiveScaffold::DataStructures::ActionLink.new('show_search', :label => :search, :type => :collection, :security_method => :search_authorized?, :ignore_method => :field_search_ignore?)

    # A flag for how the search should do full-text searching in the database:
    # * :full: LIKE %?%
    # * :start: LIKE ?%
    # * :end: LIKE %?
    # * false: LIKE ?
    # Default is :full
    cattr_accessor :text_search
    @@text_search = :full

    # human conditions
    # instead of just filtered you may show the user a humanized search condition statment
    cattr_accessor :human_conditions
    @@human_conditions = false

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
      @optional_columns ||= []
    end

    # default search params
    # default_params = {:title => {"from"=>"test", "to"=>"", "opt"=>"%?%"}}
    attr_accessor :default_params

    # human conditions
    # instead of just filtered you may show the user a humanized search condition statment
    attr_accessor :human_conditions
  end
end
