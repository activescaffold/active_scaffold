module ActiveScaffold::Actions
  module Search
    include ActiveScaffold::Actions::CommonSearch
    def self.included(base)
      base.before_filter :search_authorized_filter, :only => :show_search
      base.before_filter :store_search_params_into_session, :only => [:index]
      base.before_filter :do_search, :only => [:index]
      base.helper_method :search_params
    end

    def show_search
      respond_to_action(:search)
    end

    protected
    def search_respond_to_html
      render(:action => "search")
    end
    def search_respond_to_js
      render(:partial => "search")
    end
    def do_search
      query = search_params.to_s.strip rescue ''
      unless query.empty?
        columns = active_scaffold_config.search.columns
        text_search = active_scaffold_config.search.text_search
        query = query.split(active_scaffold_config.search.split_terms) if active_scaffold_config.search.split_terms
        search_conditions = self.class.create_conditions_for_columns(query, columns, text_search)
        @filtered = !search_conditions.blank?
        self.active_scaffold_conditions.concat search_conditions if @filtered

        includes_for_search_columns = columns.collect{ |column| column.includes}.flatten.uniq.compact
        self.active_scaffold_includes.concat includes_for_search_columns

        active_scaffold_config.list.user.page = nil
      end
    end

    private
    def search_authorized_filter
      link = active_scaffold_config.search.link || active_scaffold_config.search.class.link
      raise ActiveScaffold::ActionNotAllowed unless self.send(link.security_method)
    end
    def search_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.search.formats).uniq
    end
  end
end
