module ActiveScaffold::Actions
  module List
    def self.included(base)
      base.before_filter :list_authorized_filter, :only => [:index, :table, :update_table, :row, :list]
    end

    def index
      list
    end

    def table
      do_list
      render(:action => 'list', :layout => false)
    end

    # This is called when changing pages, sorts and search
    def update_table
      do_list
      respond_to_action(:update_table)
    end

    # get just a single row
    def row
      render :partial => 'list_record', :locals => {:record => find_if_allowed(params[:id], :read)}
    end

    def list
      do_list
      if active_scaffold_config.list.always_show_create
        do_new
      end
      respond_to_action(:list)
    end
    
    protected
    def list_respond_to_html
      render :action => 'list'
    end
    def list_respond_to_js
      render :action => 'list', :layout => false
    end
    def list_respond_to_xml
      render :xml => response_object.to_xml, :content_type => Mime::XML, :status => response_status
    end
    def list_respond_to_json
      render :text => response_object.to_json, :content_type => Mime::JSON, :status => response_status
    end
    def list_respond_to_yaml
      render :text => response_object.to_yaml, :content_type => Mime::YAML, :status => response_status
    end
    def update_table_respond_to_html
      return_to_main
    end
    def update_table_respond_to_js
      render(:partial => 'list')
    end
    # The actual algorithm to prepare for the list view
    def do_list
      includes_for_list_columns = active_scaffold_config.list.columns.collect{ |c| c.includes }.flatten.uniq.compact
      self.active_scaffold_joins.concat includes_for_list_columns

      options = { :sorting => active_scaffold_config.list.user.sorting,
                  :count_includes => active_scaffold_config.list.user.count_includes }
      paginate = (params[:format].nil?) ? (accepts? :html, :js) : ['html', 'js'].include?(params[:format])
      if paginate
        options.merge!({
          :per_page => active_scaffold_config.list.user.per_page,
          :page => active_scaffold_config.list.user.page
        })
      end

      page = find_page(options);
      if page.items.try(:empty?)
        page = page.pager.first
        active_scaffold_config.list.user.page = 1
      end
      @page, @records = page, page.items
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def list_authorized?
      authorized_for?(:action => :read)
    end
    private
    def list_authorized_filter
      raise ActiveScaffold::ActionNotAllowed unless list_authorized?
    end
    def update_table_formats
      (default_formats + active_scaffold_config.formats).uniq
    end
    def list_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.list.formats).uniq
    end
  end
end
