module ActiveScaffold::Actions
  module List
    def self.included(base)
      base.before_filter :list_authorized_filter, :only => [:index, :row]
      base.helper_method :list_columns
    end

    def index
      list
    end

    # get just a single row
    def row
      render :partial => 'row', :locals => {:record => find_if_allowed(params[:id], :read)}
    end

    def list
      do_list
      do_new if active_scaffold_config.list.always_show_create
      @record ||= active_scaffold_config.model.new if active_scaffold_config.list.always_show_search
      @nested_auto_open = active_scaffold_config.list.nested_auto_open
      respond_to_action(:list)
    end
    
    protected
    def list_respond_to_html
      if params.delete(:embedded)
        render :action => 'list', :layout => false
      else
        render :action => 'list'
      end
    end
    def list_respond_to_js
      if params[:adapter]
        render(:partial => 'list_with_header')
      elsif params[:embedded]
        params.delete(:embedded)
        render(:partial => 'list_with_header')
      else
        render :action => 'list.js'
      end
    end
    def list_respond_to_xml
      render :xml => response_object.to_xml(:only => active_scaffold_config.list.columns.names), :content_type => Mime::XML, :status => response_status
    end
    def list_respond_to_json
      render :text => response_object.to_json(:only => active_scaffold_config.list.columns.names), :content_type => Mime::JSON, :status => response_status
    end
    def list_respond_to_yaml
      render :text => Hash.from_xml(response_object.to_xml(:only => active_scaffold_config.list.columns.names)).to_yaml, :content_type => Mime::YAML, :status => response_status
    end
    # The actual algorithm to prepare for the list view
    def do_list
      includes_for_list_columns = active_scaffold_config.list.columns.collect{ |c| c.includes }.flatten.uniq.compact
      self.active_scaffold_includes.concat includes_for_list_columns

      options = { :sorting => active_scaffold_config.list.user.sorting,
                  :count_includes => active_scaffold_config.list.user.count_includes }
      paginate = (params[:format].nil?) ? (accepts? :html, :js) : ['html', 'js'].include?(params[:format])
      if paginate
        options.merge!({
          :per_page => active_scaffold_config.list.user.per_page,
          :page => active_scaffold_config.list.user.page, 
          :pagination => active_scaffold_config.list.pagination
        })
      end

      page = find_page(options);
      if page.items.blank? && !page.pager.infinite?
        page = page.pager.last
        active_scaffold_config.list.user.page = page.number
      end
      @page, @records = page, page.items
    end

    def each_record_in_scope
      do_search if respond_to? :do_search
      finder_options = { :order => "#{active_scaffold_config.model.primary_key} ASC",
                         :conditions => all_conditions,
                         :joins => joins_for_finder}
      finder_options.merge! custom_finder_options
      finder_options.merge! :include => (active_scaffold_includes.blank? ? nil : active_scaffold_includes)
      klass = beginning_of_chain
      klass.all(finder_options).each {|record| yield record}
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def list_authorized?
      authorized_for?(:crud_type => :read)
    end
    
    def action_update_respond_to_js
      render(:action => 'on_action_update')
    end

    def action_update_respond_to_xml
      render :xml => successful? ? "" : response_object.to_xml(:only => active_scaffold_config.list.columns.names), :content_type => Mime::XML, :status => response_status
    end

    def action_update_respond_to_json
      render :text => successful? ? "" : response_object.to_json(:only => active_scaffold_config.list.columns.names), :content_type => Mime::JSON, :status => response_status
    end

    def action_update_respond_to_yaml
      render :text => successful? ? "" : Hash.from_xml(response_object.to_xml(:only => active_scaffold_config.list.columns.names)).to_yaml, :content_type => Mime::YAML, :status => response_status
    end
     
    private
    def list_authorized_filter
      raise ActiveScaffold::ActionNotAllowed unless list_authorized?
    end
    def list_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.list.formats).uniq
    end
    def action_update_formats
      (default_formats + active_scaffold_config.formats).uniq
    end

    def list_columns
      active_scaffold_config.list.columns.collect_visible
    end
  end
end
