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
      respond_to do |type|
        type.html do
          if successful?
            render(:partial => "field_search", :layout => true)
          else
            return_to_main
          end
        end
        type.js { render(:partial => "field_search", :layout => false) }
      end
    end

    protected

    def do_search
      unless params[:search].nil?
        like_pattern = active_scaffold_config.field_search.full_text_search? ? '%?%' : '?%'
        conditions = self.active_scaffold_conditions
        params[:search].each do |key, value|
          next if !active_scaffold_config.field_search.columns.include?(key) or value.nil? or value.empty?
          case active_scaffold_config.columns[key].ui_type
          when :boolean, :integer
            conditions = merge_conditions(conditions, ["#{active_scaffold_config.columns[key].search_sql} = ?", value])
          else
            conditions = merge_conditions(conditions, ["LOWER(#{active_scaffold_config.columns[key].search_sql}) LIKE ?", like_pattern.sub(/\?/, value.downcase)])
          end
        end
        self.active_scaffold_conditions = conditions

        columns = active_scaffold_config.field_search.columns
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
  end
end
