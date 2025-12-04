# frozen_string_literal: true

module ActiveScaffold::Actions
  module List
    def self.included(base)
      base.before_action :list_authorized_filter, only: :index
      base.helper_method :list_columns, :count_on_association_class?
    end

    def index
      if params[:action_links] && request.xhr?
        action_links_menu
      elsif params[:id] && !params[:id].is_a?(Array) && request.xhr?
        row
      else
        list
      end
    end

    protected

    def action_links_menu
      @record = find_if_allowed(params[:id], :read) if params[:id]
      @action_links = params[:action_links].split('.').reduce(active_scaffold_config.action_links) do |links, submenu|
        links.subgroup(submenu)
      end
      respond_to_action(:action_links_menu, action_links_menu_formats)
    end

    def action_links_menu_formats
      %i[js]
    end

    # get just a single row
    def row
      get_row
      respond_to_action(:row)
    end

    def list
      if %w[index list].include? action_name
        do_list
      else
        do_refresh_list
      end
      respond_to_action(:list)
    end

    def list_respond_to_html
      if loading_embedded?
        render action: 'list', layout: false
      else
        render action: 'list'
      end
    end

    def list_respond_to_js
      if params[:adapter] || loading_embedded?
        render partial: 'list_with_header'
      else
        @auto_pagination = params[:auto_pagination]
        @popstate = params.delete(:_popstate)
        render partial: 'refresh_list', formats: [:js]
      end
    end

    def list_respond_to_xml
      response_to_api(:xml, list_columns_names)
    end

    def list_respond_to_json
      response_to_api(:json, list_columns_names)
    end

    def row_respond_to_html
      render partial: 'row', locals: {record: @record}
    end

    def row_respond_to_js
      render action: 'row'
    end

    def action_links_menu_respond_to_js
      render action: 'action_links_menu'
    end

    # The actual algorithm to prepare for the list view
    def set_includes_for_columns(action = :list, sorting = active_scaffold_config.list.user.sorting)
      @cache_associations = true
      columns = columns_for_action(action)
      joins_cols, preload_cols = columns.select { |c| c.includes.present? }.partition do |col|
        includes_need_join?(col, sorting) && !grouped_search?
      end
      active_scaffold_references.concat joins_cols.map(&:includes).flatten.uniq
      active_scaffold_preload.concat preload_cols.map(&:includes).flatten.uniq
      set_includes_for_sorting(columns, sorting) if sorting.sorts_by_sql?
    end

    def columns_for_action(action)
      if respond_to?(:"#{action}_columns", true)
        send(:"#{action}_columns")
      else
        active_scaffold_config.send(action).columns.visible_columns(flatten: true)
      end
    end

    def set_includes_for_sorting(columns, sorting)
      sorting.each_column do |col|
        next if sorting.constraint_columns.include? col.name
        next unless col.includes.present? && columns.exclude?(col)

        if active_scaffold_config.model.connection.needs_order_expressions_in_select?
          active_scaffold_references << col.includes
        else
          active_scaffold_outer_joins << col.includes
        end
      end
    end

    def includes_need_join?(column, sorting = active_scaffold_config.list.user.sorting)
      (sorting.sorts_by_sql? && sorting.sorts_on?(column)) || scoped_habtm?(column)
    end

    def scoped_habtm?(column)
      assoc = column.association if column.association&.collection?
      assoc&.habtm? && assoc.scope
    end

    def get_row(crud_type_or_security_options = :read)
      set_includes_for_columns
      super
      cache_column_counts [@record]
    end

    def current_page
      set_includes_for_columns

      page = find_page(find_page_options)
      total_pages = page.pager.number_of_pages
      if !page.pager.infinite? && !total_pages.zero? && page.number > total_pages
        page = page.pager.last
        active_scaffold_config.list.user.page = page.number
      end
      page
    end

    # The actual algorithm to prepare for the list view
    def do_list
      # id: nil needed in params_for because rails reuse it even
      # if it was deleted from params (like do_refresh_list does)
      @remove_id_from_list_links = params[:id].blank?
      @page = current_page
      @records = @page.items
      cache_column_counts @records
    end

    def columns_to_cache_counts
      list_columns.select(&:cache_count?)
    end

    def cache_column_counts(records)
      @counts = columns_to_cache_counts.each_with_object({}) do |column, counts|
        if ActiveScaffold::OrmChecks.active_record?(column.association.klass)
          counts[column.name] = count_query_for_column(column, records).count
        elsif ActiveScaffold::OrmChecks.mongoid?(column.association.klass)
          counts[column.name] = mongoid_count_for_column(column, records)
        end
      end
    end

    def count_on_association_class?(column)
      column.association.has_many? && !column.association.through? &&
        (!column.association.as || column.association.reverse_association)
    end

    def count_query_for_column(column, records)
      if count_on_association_class?(column)
        count_query_on_association_class(column, records)
      else
        count_query_with_join(column, records)
      end
    end

    def count_query_on_association_class(column, records)
      key = column.association.primary_key || :id
      query = column.association.klass.where(column.association.foreign_key => records.map(&key.to_sym))
      if column.association.as
        query.where!(column.association.reverse_association.foreign_type => active_scaffold_config.model.name)
      end
      query = query.instance_exec(&column.association.scope) if column.association.scope
      query.group(column.association.foreign_key)
    end

    def count_query_with_join(column, records)
      klass = column.association.klass
      query = active_scaffold_config.model.where(active_scaffold_config.primary_key => records.map(&:id))
                .joins(column.name).group(active_scaffold_config.primary_key)
                .select("#{klass.quoted_table_name}.#{klass.quoted_primary_key}")
      if column.association.scope && klass.instance_exec(&column.association.scope).values[:distinct]
        query = query.distinct
      end
      query
    end

    def mongoid_count_for_column(column, records)
      matches = {column.association.foreign_key => {'$in': records.map(&:id)}}
      if column.association.as
        matches[column.association.reverse_association.foreign_type] = {'$eq': active_scaffold_config.model.name}
      end
      group = {_id: "$#{column.association.foreign_key}", count: {'$sum' => 1}}
      query = column.association.klass.collection.aggregate([{'$match' => matches}, {'$group' => group}])
      query.each_with_object({}) do |row, hash|
        hash[row['_id']] = row['count']
      end
    end

    def find_page_options
      options = {
        sorting: active_scaffold_config.list.user.sorting,
        count_includes: active_scaffold_config.list.user.count_includes
      }

      paginate = params[:format].nil? ? accepts?(:html, :js) : %w[html js].include?(params[:format])
      options[:pagination] = active_scaffold_config.list.pagination if paginate
      if options[:pagination]
        options[:per_page] = active_scaffold_config.list.user.per_page
        options[:page] = active_scaffold_config.list.user.page
      end

      if active_scaffold_config.list.auto_select_columns
        auto_select_columns = list_columns + [active_scaffold_config.columns[active_scaffold_config.model.primary_key]]
        options[:select] = auto_select_columns.filter_map { |c| quoted_select_columns(c.select_columns) }.flatten
      end

      options
    end

    def quoted_select_columns(columns)
      columns&.map do |col, name|
        sql_column = active_scaffold_config.columns[col]&.field || col
        name ? Arel.sql(sql_column).as(name) : sql_column
      end
    end

    def do_refresh_list
      params.delete(:id)
      if respond_to? :do_search, true
        store_search_params_into_session if search_params.blank?
        do_search
      end
      do_list
    end

    def each_record_in_page(&)
      page_items.each(&)
    end

    def each_record_in_scope(&)
      scoped_query.each(&)
    end

    def page_items
      @page_items ||= begin
        page_number = active_scaffold_config.list.user.page
        do_search if respond_to? :do_search, true
        active_scaffold_config.list.user.page = page_number
        @page = current_page
        @page.items
      end
    end

    def filtered_query
      apply_filters beginning_of_chain
    end

    def filters_enabled?
      active_scaffold_config.list.filters.present? && params[:id].nil?
    end

    def apply_filters(query)
      return query unless filters_enabled?

      active_scaffold_config.list.refresh_with_header = true

      active_scaffold_config.list.filters.inject(query) do |q, filter|
        next q unless filter.security_method.nil? || send(filter.security_method)

        default_option = filter[filter.default_option]
        apply_filter q, params[filter.name] ? filter[params[filter.name]] : default_option, default_option
      end
    end

    def apply_filter(query, filter_option, default_option)
      return query if filter_option.nil? || (filter_option.security_method_set? && !send(filter_option.security_method))

      @applied_filters ||= []
      @applied_filters << filter_option unless filter_option == default_option
      case filter_option.conditions
      when Proc then instance_exec query, &filter_option.conditions
      else query.where(filter_option.conditions)
      end
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
      authorized_for?(crud_type: :read)
    end

    def action_update_respond_to_js
      do_refresh_list if @record.blank?
      super
    end

    def objects_for_etag
      objects =
        if @list_columns
          if active_scaffold_config.list.calculate_etag
            @records.to_a
          elsif active_scaffold_config.list.user.sorting
            {etag: active_scaffold_config.list.user.sorting.clause}
          end
        end
      objects.presence || super
    end

    private

    def list_authorized_filter
      raise ActiveScaffold::ActionNotAllowed unless list_authorized?
    end

    def list_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.list.formats).uniq
    end
    alias index_formats list_formats

    def row_formats
      (%i[html js] + active_scaffold_config.formats + active_scaffold_config.list.formats).uniq
    end

    def action_update_formats
      (default_formats + active_scaffold_config.formats).uniq
    end

    def action_confirmation_formats
      (default_formats + active_scaffold_config.formats).uniq
    end

    def list_columns
      @list_columns ||= active_scaffold_config.list.columns.visible_columns
    end

    def list_columns_names
      list_columns.collect(&:name)
    end
  end
end
