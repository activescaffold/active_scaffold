module ActiveScaffold::Config
  class List < Base
    self.crud_type = :read

    def initialize(core_config)
      super
      # inherit from global scope
      # full configuration path is: defaults => global table => local table
      @per_page = self.class.per_page
      @page_links_inner_window = self.class.page_links_inner_window
      @page_links_outer_window = self.class.page_links_outer_window

      # originates here
      @sorting = ActiveScaffold::DataStructures::Sorting.new(@core.columns, @core.model)
      @sorting.set_default_sorting

      # inherit from global scope
      @empty_field_text = self.class.empty_field_text
      @association_join_text = self.class.association_join_text
      @pagination = self.class.pagination
      @auto_pagination = self.class.auto_pagination
      @show_search_reset = self.class.show_search_reset
      @reset_link = self.class.reset_link.clone
      @wrap_tag = self.class.wrap_tag
      @always_show_search = self.class.always_show_search
      @always_show_create = self.class.always_show_create
      @messages_above_header = self.class.messages_above_header
      @auto_select_columns = self.class.auto_select_columns
      @refresh_with_header = self.class.refresh_with_header
      @calculate_etag = self.class.calculate_etag
    end

    # global level configuration
    # --------------------------
    # include list header on refresh
    cattr_accessor :refresh_with_header, instance_accessor: false
    @@refresh_with_header = false

    # how many records to show per page
    cattr_accessor :per_page, instance_accessor: false
    @@per_page = 15

    # how many page links around current page to show
    cattr_accessor :page_links_inner_window, instance_accessor: false
    @@page_links_inner_window = 2

    # how many page links around first and last page to show
    cattr_accessor :page_links_outer_window, instance_accessor: false
    @@page_links_outer_window = 0

    # what string to use when a field is empty
    cattr_accessor :empty_field_text, instance_accessor: false
    @@empty_field_text = '-'

    # display messages above table header
    cattr_accessor :messages_above_header, instance_accessor: false
    @@messages_above_header = false

    # what string to use to join records from plural associations
    cattr_accessor :association_join_text, instance_accessor: false
    @@association_join_text = ', '

    # What kind of pagination to use:
    # * true: The usual pagination
    # * :infinite: Treat the source as having an infinite number of pages (i.e. don't count the records; useful for large tables where counting is slow and we don't really care anyway)
    # * false: Disable pagination
    cattr_accessor :pagination, instance_accessor: false
    @@pagination = true

    # Auto paginate, only can be used with pagination enabled
    # * true: First page will be loaded on first request, next pages will be requested by AJAX until all items are loaded
    # * false: Disable auto pagination
    cattr_accessor :auto_pagination, instance_accessor: false
    @@auto_pagination = false

    # show a link to reset the search next to filtered message
    cattr_accessor :show_search_reset, instance_accessor: false
    @@show_search_reset = true

    # the ActionLink to reset search
    cattr_reader :reset_link, instance_reader: false
    @@reset_link = ActiveScaffold::DataStructures::ActionLink.new('index', :label => :click_to_reset, :type => :collection, :position => false, :parameters => {:search => ''})

    # wrap normal cells (not inplace editable columns or with link) with a tag
    # it allows for more css styling
    cattr_accessor :wrap_tag, instance_accessor: false
    @@wrap_tag = nil

    # Show search form in the list header instead of display the link
    cattr_accessor :always_show_search, instance_accessor: false
    @@always_show_search = false

    # Show create form in the list header instead of display the link
    cattr_accessor :always_show_create, instance_accessor: false
    @@always_show_create = false

    # Enable auto select columns on list, so only columns needed for list columns are selected
    cattr_accessor :auto_select_columns, instance_accessor: false
    @@auto_select_columns = false

    # Enable ETag calculation (when conditional_get_support is enabled), it requires to load records for page, when is disabled query can be avoided when page is cached in browser
    # order clause will be used for ETag when calculate_etag is disabled, so query for records can be avoided
    cattr_accessor :calculate_etag, instance_accessor: false
    @@calculate_etag = false

    # instance-level configuration
    # ----------------------------

    columns_accessor :columns

    # include list header on refresh
    attr_accessor :refresh_with_header

    # how many rows to show at once
    attr_accessor :per_page

    # how many page links around current page to show
    attr_accessor :page_links_inner_window

    # how many page links around current page to show
    attr_accessor :page_links_outer_window

    # What kind of pagination to use:
    # * true: The usual pagination
    # * :infinite: Treat the source as having an infinite number of pages (i.e. don't count the records; useful for large tables where counting is slow and we don't really care anyway)
    # * false: Disable pagination
    attr_accessor :pagination

    # Auto paginate, only can be used with pagination enabled
    # * true: First page will be loaded on first request, next pages will be requested by AJAX until all items are loaded
    # * false: Disable auto pagination
    attr_accessor :auto_pagination

    # what string to use when a field is empty
    attr_accessor :empty_field_text

    # display messages above table header
    attr_accessor :messages_above_header

    # what string to use to join records from plural associations
    attr_accessor :association_join_text

    # show a link to reset the search next to filtered message
    attr_accessor :show_search_reset

    # the ActionLink to reset search
    attr_reader :reset_link

    # the default sorting.
    # should be a hash of {column_name => direction}, e.g. {:a => 'desc', :b => 'asc'}.
    # for backwards compatibility, it may be an array of hashes of {column_name => direction}, e.g. [{:a => 'desc'}, {:b => 'asc'}].
    # to just sort on one column, you can simply provide a hash, e.g. {:a => 'desc'}.
    def sorting=(val)
      val = [val] if val.is_a? Hash
      sorting.set(*val)
    end

    def sorting
      @sorting ||= ActiveScaffold::DataStructures::Sorting.new(@core.columns, @core.model)
    end

    # overwrite the includes used for the count sql query
    attr_accessor :count_includes

    # the label for this List action. used for the header.
    attr_writer :label
    def label
      @label ? as_(@label, :count => 2) : @core.label(:count => 2)
    end

    attr_writer :no_entries_message
    def no_entries_message
      @no_entries_message ? @no_entries_message : :no_entries
    end

    attr_writer :filtered_message
    def filtered_message
      @filtered_message ? @filtered_message : :filtered
    end

    attr_writer :always_show_search
    def always_show_search
      @always_show_search && search_partial.present?
    end

    def search_partial
      if @always_show_search == true
        auto_search_partial
      elsif @core.actions.include? @always_show_search
        @always_show_search.to_s
      end
    end

    def auto_search_partial
      return 'search' if @core.actions.include?(:search)
      return 'field_search' if @core.actions.include?(:field_search)
    end

    # always show create
    attr_writer :always_show_create
    def always_show_create
      @always_show_create && @core.actions.include?(:create)
    end

    # if list view is nested hide nested_column
    attr_writer :hide_nested_column
    def hide_nested_column
      @hide_nested_column.nil? ? true : @hide_nested_column
    end

    # wrap normal cells (not inplace editable columns or with link) with a tag
    # it allows for more css styling
    attr_accessor :wrap_tag

    # Enable auto select columns on list, so only columns needed for list columns are selected
    attr_accessor :auto_select_columns

    # Enable ETag calculation (when conditional_get_support is enabled), it requires to load records for page, when is disabled query can be avoided when page is cached in browser
    # order clause will be used for ETag when calculate_etag is disabled, so query for records can be avoided
    attr_accessor :calculate_etag

    # don't inherit, defined with columns_accessor, class_eval would complain about block too long
    class UserSettings
      user_attr :page_links_inner_window, :page_links_outer_window, :refresh_with_header, :empty_field_text,
                :association_join_text, :messages_above_header, :wrap_tag, :auto_select_columns, :calculate_etag,
                :no_entries_message, :filtered_message, :show_search_reset, :always_show_create, :always_show_search,
                :hide_nested_column, :pagination, :auto_pagination

      def initialize(conf, storage, params)
        super(conf, storage, params, :list)
        @_sorting = nil
      end

      attr_writer :label
      # This label has already been localized.
      def label
        self['label'] || embedded_label || @label || @conf.label
      end

      def embedded_label
        @params.dig :embedded, :label
      end

      def per_page
        self['per_page'] = @params['limit'].to_i if @params.key? 'limit'
        self['per_page'] || @conf.per_page
      end

      def per_page=(value)
        self['per_page'] = value
      end

      def page
        self['page'] = @params['page'] || 1 if @params.key?('page') || @conf.auto_pagination
        self['page'] || 1
      end

      def page=(value = nil)
        self['page'] = value
      end

      attr_reader :nested_default_sorting

      def nested_default_sorting=(options)
        @nested_default_sorting ||= sorting_dup
        @nested_default_sorting.set_nested_sorting(options[:table_name], options[:default_sorting])
      end

      def default_sorting
        nested_default_sorting.nil? || @sorting.present? ? sorting_dup : nested_default_sorting
      end

      # TODO: programatically set sorting, for per-request configuration, priority @params, then @sort

      def user_sorting?
        @params['sort'] && @params['sort_direction'] != 'reset'
      end

      # change list sorting for this request, unless sorting is defined
      # {column => direction, column => direction}
      attr_writer :sorting

      def sorting
        if @_sorting.nil?
          # we want to store as little as possible in the session, but we want to return a Sorting data structure. so we recreate it each page load based on session data.
          self['sort'] = [@params['sort'], @params['sort_direction']] if @params['sort'] && @params['sort_direction']
          self['sort'] = nil if @params['sort_direction'] == 'reset'

          if self['sort'] && @conf.core.columns[self['sort'][0]]
            sorting = sorting_dup
            sorting.set(*self['sort'])
            @_sorting = sorting
          else
            @_sorting = default_sorting
            @_sorting.set(*@sorting) if @sorting
            if @conf.columns.constraint_columns.present?
              @_sorting.constraint_columns = @conf.columns.constraint_columns
            end
          end
        end
        @_sorting
      end

      def count_includes
        @conf.count_includes
      end

      protected

      def sorting_dup
        sorting = @conf.sorting.dup
        # access to config instance columns instead of config class columns, in case columns are changed in this request
        sorting.instance_variable_set :@columns, core.columns
        sorting
      end
    end
  end
end
