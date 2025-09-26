# frozen_string_literal: true

module ActiveScaffold::Config
  class Search < Base
    self.crud_type = :read

    def initialize(core_config)
      super
      @text_search = self.class.text_search
      @live = self.class.live?
      @split_terms = self.class.split_terms
      @reset_form = self.class.reset_form
    end

    # global level configuration
    # --------------------------
    # the ActionLink for this action
    cattr_accessor :link, instance_accessor: false
    @@link = ActiveScaffold::DataStructures::ActionLink.new('show_search', label: :search, type: :collection, security_method: :search_authorized?, ignore_method: :search_ignore?)

    # A flag for how the search should do full-text searching in the database:
    # * :full: LIKE %?%
    # * :start: LIKE ?%
    # * :end: LIKE %?
    # * false: LIKE ?
    # Default is :full
    cattr_accessor :text_search, instance_accessor: false
    @@text_search = :full

    # whether submits the search as you type
    cattr_writer :live, instance_writer: false
    def self.live?
      @@live
    end

    cattr_accessor :split_terms, instance_accessor: false
    @@split_terms = ' '

    cattr_accessor :reset_form, instance_accessor: false

    # instance-level configuration
    # ----------------------------

    # provides access to the list of columns specifically meant for the Search to use
    def columns
      # we want to delay initializing to the @core.columns set for as long as possible. Too soon and .search_sql will not be available to .searchable?
      unless defined? @columns
        self.columns = @core.columns.filter_map { |c| c.name if @core.columns._inheritable.include?(c.name) && c.searchable? && c.association.nil? && c.text? }
      end
      @columns
    end
    columns_accessor :columns

    # A flag for how the search should do full-text searching in the database:
    # * :full: LIKE %?%
    # * :start: LIKE ?%
    # * :end: LIKE %?
    # * false: LIKE ?
    # Default is :full
    attr_accessor :text_search

    attr_accessor :split_terms, :reset_form

    # the ActionLink for this action
    attr_accessor :link

    # whether submits the search as you type
    attr_writer :live

    def live?
      @live
    end

    UserSettings.class_eval do
      attr_writer :live

      def live?
        defined?(@live) ? @live : @conf.live?
      end

      user_attr :text_search, :split_terms
    end
  end
end
