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
      @sorting = ActiveScaffold::DataStructures::Sorting.new(@core.columns)
      @sorting.set_default_sorting(@core.model)

      # inherit from global scope
      @empty_field_text = self.class.empty_field_text
      @association_join_text = self.class.association_join_text
      @pagination = self.class.pagination
      @show_search_reset = self.class.show_search_reset
      @reset_link = self.class.reset_link.clone
      @wrap_tag = self.class.wrap_tag
      @always_show_search = self.class.always_show_search
      @always_show_create = self.class.always_show_create
      @messages_above_header = self.class.messages_above_header
    end

    # global level configuration
    # --------------------------
    # how many records to show per page
    cattr_accessor :per_page
    @@per_page = 15

    # how many page links around current page to show
    cattr_accessor :page_links_inner_window
    @@page_links_inner_window = 2

    # how many page links around first and last page to show
    cattr_accessor :page_links_outer_window
    @@page_links_outer_window = 0
    
    # what string to use when a field is empty
    cattr_accessor :empty_field_text
    @@empty_field_text = '-'

    # display messages above table header
    cattr_accessor :messages_above_header
    @@messages_above_header = false

    # what string to use to join records from plural associations
    cattr_accessor :association_join_text
    @@association_join_text = ', '

    # What kind of pagination to use:
    # * true: The usual pagination
    # * :infinite: Treat the source as having an infinite number of pages (i.e. don't count the records; useful for large tables where counting is slow and we don't really care anyway)
    # * false: Disable pagination
    cattr_accessor :pagination
    @@pagination = true

    # show a link to reset the search next to filtered message
    cattr_accessor :show_search_reset
    @@show_search_reset = true

    # the ActionLink to reset search
    cattr_reader :reset_link
    @@reset_link = ActiveScaffold::DataStructures::ActionLink.new('index', :label => :click_to_reset, :type => :collection, :position => false, :parameters => {:search => ''})

    # wrap normal cells (not inplace editable columns or with link) with a tag
    # it allows for more css styling
    cattr_accessor :wrap_tag
    @@wrap_tag = nil

    # Show search form in the list header instead of display the link
    cattr_accessor :always_show_search
    @@always_show_search = false
    
    # Show create form in the list header instead of display the link
    cattr_accessor :always_show_create
    @@always_show_create = false

    # instance-level configuration
    # ----------------------------

    # provides access to the list of columns specifically meant for the Table to use
    def columns
      self.columns = @core.columns._inheritable unless @columns # lazy evaluation
      @columns
    end
    
    public :columns=

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

    # the default sorting. should be an array of hashes of {column_name => direction}, e.g. [{:a => 'desc'}, {:b => 'asc'}]. to just sort on one column, you can simply provide a hash, though, e.g. {:a => 'desc'}.
    def sorting=(val)
      val = [val] if val.is_a? Hash
      sorting.clear
      val.each { |clause| sorting.add *Array(clause).first }
    end
    def sorting
      @sorting ||= ActiveScaffold::DataStructures::Sorting.new(@core.columns)
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
      @always_show_search && !search_partial.blank?
    end
    
    def search_partial
      return "search" if @core.actions.include?(:search)
      return "field_search" if @core.actions.include?(:field_search)
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
    
    # might be set to open nested_link automatically in view
    # conf.nested.add_link(:players)
    # conf.list.nested_auto_open = {:players => 2}
    # will open nested players view if there are 2 or less records in parent
    attr_accessor :nested_auto_open
    
    # wrap normal cells (not inplace editable columns or with link) with a tag
    # it allows for more css styling
    attr_accessor :wrap_tag
    
    class UserSettings < UserSettings
      def initialize(conf, storage, params)
        super(conf,storage,params)
        @sorting = nil
      end
      
      # This label has alread been localized.
      def label
        @session[:label] ? @session[:label] : @conf.label
      end

      def per_page
        @session['per_page'] = @params['limit'].to_i if @params.has_key? 'limit'
        @session['per_page'] || @conf.per_page
      end

      def page
        @session['page'] = @params['page'] if @params.has_key? 'page'
        @session['page'] || 1
      end

      def page=(value = nil)
        @session['page'] = value
      end

      attr_reader :nested_default_sorting

      def nested_default_sorting=(options)
        @nested_default_sorting ||= @conf.sorting.clone
        @nested_default_sorting.set_nested_sorting(options[:table_name], options[:default_sorting])
      end

      def default_sorting
        nested_default_sorting.nil? ? @conf.sorting : nested_default_sorting
      end

      def sorting
        if @sorting.nil?
          # we want to store as little as possible in the session, but we want to return a Sorting data structure. so we recreate it each page load based on session data.
          @session['sort'] = [@params['sort'], @params['sort_direction']] if @params['sort'] and @params['sort_direction']
          @session['sort'] = nil if @params['sort_direction'] == 'reset'

          if @session['sort']
            sorting = @conf.sorting.clone
            sorting.set(*@session['sort'])
            @sorting = sorting
          else
            @sorting = default_sorting
          end
        end
        @sorting
      end
      
      def count_includes
        @conf.count_includes
      end
    end
  end
end
