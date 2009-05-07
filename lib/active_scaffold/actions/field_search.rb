module ActiveScaffold::Actions
  module FieldSearch
    def self.included(base)
      base.before_filter :field_search_authorized?, :only => :show_search
      base.before_filter :do_search
    end

    # FieldSearch uses params[:search] and not @record because search conditions do not always pass the Model's validations.
    # This facilitates for example, textual searches against associations via .search_sql
    def show_search
      params[:search] ||= {}
      @record = active_scaffold_config.model.new
      respond_to do |type|
        field_search_formats.each do |format|
          type.send(format){ send("field_search_respond_to_#{format}") }
        end
      end
    end

    protected
    def field_search_respond_to_html
      render(:action => "field_search")
    end
    
    def field_search_respond_to_js
      render(:partial => "field_search")
    end

    def do_search
      unless params[:search].nil?
        like_pattern = active_scaffold_config.field_search.full_text_search? ? '%?%' : '?%'
        search_conditions = []
        columns = active_scaffold_config.field_search.columns
        columns.each do |column|
          search_conditions << self.class.condition_for_column(column, params[:search][column.name], like_pattern)
        end
        search_conditions.compact!
        self.active_scaffold_conditions = merge_conditions(self.active_scaffold_conditions, *search_conditions)
        @filtered = !search_conditions.blank?

        includes_for_search_columns = columns.collect{ |column| column.includes}.flatten.uniq.compact
        self.active_scaffold_joins.concat includes_for_search_columns

        active_scaffold_config.list.user.page = nil
      end
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def field_search_authorized?
      authorized_for?(:action => :read)
    end
    private
    def field_search_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.field_search.formats).uniq
    end
  end
end
