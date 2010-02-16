module ActiveScaffold::Config
  class Search < Base
    self.crud_type = :read

    def initialize(core_config)
      @core = core_config

      @text_search = self.class.text_search

      # start with the ActionLink defined globally
      @link = self.class.link.clone
    end


    # global level configuration
    # --------------------------
    # the ActionLink for this action
    cattr_accessor :link
    @@link = ActiveScaffold::DataStructures::ActionLink.new('show_search', :label => :search, :type => :collection, :security_method => :search_authorized?)

    def self.full_text_search=(value)
      ::ActiveSupport::Deprecation.warn("full_text_search is deprecated, use text_search = :full instead", caller)
      @@text_search = :full
    end
    def self.full_text_search?
      ::ActiveSupport::Deprecation.warn("full_text_search? is deprecated, use text_search == :full instead", caller)
      @@text_search == :full
    end
    cattr_accessor :text_search
    @@text_search = :full

    # instance-level configuration
    # ----------------------------

    # provides access to the list of columns specifically meant for the Search to use
    def columns
      # we want to delay initializing to the @core.columns set for as long as possible. Too soon and .search_sql will not be available to .searchable?
      unless @columns
        self.columns = @core.columns.collect{|c| c.name if c.searchable? and c.column and c.column.text?}.compact
      end
      @columns
    end

    public :columns=

    attr_accessor :text_search
    def full_text_search=(value)
      ::ActiveSupport::Deprecation.warn("full_text_search is deprecated, use text_search = :full instead", caller)
      @text_search = :full
    end
    def full_text_search?
      ::ActiveSupport::Deprecation.warn("full_text_search? is deprecated, use text_search == :full instead", caller)
      @text_search == :full
    end

    # the ActionLink for this action
    attr_accessor :link
  end
end
