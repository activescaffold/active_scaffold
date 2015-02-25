module ActiveScaffold::Actions
  module List
    def self.included(base)
      base.before_filter :list_authorized_filter, :only => :index
      base.helper_method :list_columns
    end

    def index
      if params[:id] && !params[:id].is_a?(Array) && request.xhr?
        row
      else
        list
      end
    end

    protected

    # get just a single row
    def row
      get_row
      respond_to_action(:row)
    end

    def list
      if %w(index list).include? action_name
        do_list
      else
        do_refresh_list
      end
      respond_to_action(:list)
    end

    def list_respond_to_html
      if loading_embedded?
        render :action => 'list', :layout => false
      else
        render :action => 'list'
      end
    end

    def list_respond_to_js
      if params[:adapter] || loading_embedded?
        render(:partial => 'list_with_header')
      else
        @auto_pagination = params[:auto_pagination]
        render :partial => 'refresh_list', :formats => [:js]
      end
    end

    def list_respond_to_xml
      render :xml => response_object.to_xml(:only => list_columns_names + [active_scaffold_config.model.primary_key], :include => association_columns(list_columns_names), :methods => virtual_columns(list_columns_names)), :content_type => Mime::XML, :status => response_status
    end

    def list_respond_to_json
      render :text => response_object.to_json(:only => list_columns_names + [active_scaffold_config.model.primary_key], :include => association_columns(list_columns_names), :methods => virtual_columns(list_columns_names)), :content_type => Mime::JSON, :status => response_status
    end

    def list_respond_to_yaml
      render :text => Hash.from_xml(response_object.to_xml(:only => list_columns_names + [active_scaffold_config.model.primary_key], :include => association_columns(list_columns_names), :methods => virtual_columns(list_columns_names))).to_yaml, :content_type => Mime::YAML, :status => response_status
    end

    def row_respond_to_html
      render(:partial => 'row', :locals => {:record => @record})
    end

    def row_respond_to_js
      render :action => 'row'
    end

    # The actual algorithm to prepare for the list view
    def set_includes_for_columns(action = :list)
      @cache_associations = true
      columns =
        if respond_to?(:"#{action}_columns", true)
          send(:"#{action}_columns")
        else
          active_scaffold_config.send(action).columns.collect_visible(:flatten => true)
        end
      sorting = active_scaffold_config.list.user.sorting
      columns_for_joins, columns_for_includes = columns.select { |c| c.includes.present? }.partition { |c| sorting.sorts_on? c }
      active_scaffold_preload.concat columns_for_includes.map(&:includes).flatten.uniq
      active_scaffold_references.concat columns_for_joins.map(&:includes).flatten.uniq
    end

    def get_row(crud_type_or_security_options = :read)
      set_includes_for_columns
      super
    end

    # The actual algorithm to prepare for the list view
    def do_list
      set_includes_for_columns

      options = {:sorting => active_scaffold_config.list.user.sorting,
        :count_includes => active_scaffold_config.list.user.count_includes}
      paginate = (params[:format].nil?) ? (accepts? :html, :js) : %w(html js).include?(params[:format])
      options[:pagination] = active_scaffold_config.list.pagination if paginate
      if options[:pagination]
        options.merge!(
          :per_page => active_scaffold_config.list.user.per_page,
          :page => active_scaffold_config.list.user.page
        )
      end
      if active_scaffold_config.list.auto_select_columns
        auto_select_columns = list_columns + [active_scaffold_config.columns[active_scaffold_config.model.primary_key]]
        options[:select] = auto_select_columns.map { |c| quoted_select_columns(c.select_columns) }.compact.flatten
      end

      page = find_page(options)
      total_pages = page.pager.number_of_pages
      if !page.pager.infinite? && !total_pages.zero? && page.number > total_pages
        page = page.pager.last
        active_scaffold_config.list.user.page = page.number
      end
      @page, @records = page, page.items
    end

    def quoted_select_columns(columns)
      columns.map { |c| active_scaffold_config.columns[c].try(:field) || c } if columns
    end

    def do_refresh_list
      params.delete(:id)
      do_search if respond_to? :do_search, true
      do_list
    end

    def each_record_in_page
      current_page = active_scaffold_config.list.user.page
      do_search if respond_to? :do_search, true
      active_scaffold_config.list.user.page = current_page
      do_list
      @page.items.each { |record| yield record }
    end

    def each_record_in_scope
      scoped_query.each { |record| yield record }
    end

    def scoped_query
      @scoped_query ||= begin
        do_search if respond_to? :do_search, true
        set_includes_for_columns
        # where(nil) is needed because we need a relation
        append_to_query(beginning_of_chain.where(nil), finder_options)
      end
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def list_authorized?
      authorized_for?(:crud_type => :read)
    end

    def action_update_respond_to_js
      do_refresh_list unless @record.present?
      super
    end

    def objects_for_etag
      objects =
        if @list_columns
          if active_scaffold_config.list.calculate_etag
            @records.to_a
          elsif active_scaffold_config.list.user.sorting
            {:etag => active_scaffold_config.list.user.sorting.clause}
          end
        end
      objects.present? ? objects : super
    end

    private

    def list_authorized_filter
      raise ActiveScaffold::ActionNotAllowed unless list_authorized?
    end

    def list_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.list.formats).uniq
    end
    alias_method :index_formats, :list_formats

    def row_formats
      ([:html, :js] + active_scaffold_config.formats + active_scaffold_config.list.formats).uniq
    end

    def action_update_formats
      (default_formats + active_scaffold_config.formats).uniq
    end

    def action_confirmation_formats
      (default_formats + active_scaffold_config.formats).uniq
    end

    def list_columns
      @list_columns ||= active_scaffold_config.list.columns.collect_visible
    end

    def list_columns_names
      list_columns.collect(&:name)
    end
  end
end
