module ActiveScaffold::Actions
  module FieldSearch
    include ActiveScaffold::Actions::Base
    def self.included(base)
      base.before_filter :do_search
    end

    def show_search
      @record = active_scaffold_config.model.new
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
      @query = ''
      unless params[:record].nil?
        like_pattern = active_scaffold_config.field_search.full_text_search? ? '%?%' : '?%'
        columns = active_scaffold_config.field_search.columns
        self.active_scaffold_conditions = merge_conditions(self.active_scaffold_conditions, ActiveScaffold::Finder.create_conditions_for_columns(@query.split(' '), columns, like_pattern))
        conditions = self.active_scaffold_conditions
        params[:record].each do |key, value|
          next if !active_scaffold_config.field_search.columns.include?(key) or value.nil? or value.empty?
          case active_scaffold_config.columns[key].ui_type
          when :boolean, :integer
            conditions = merge_conditions(conditions, ["#{active_scaffold_config.columns[key].search_sql} = ?", value])
          else
            conditions = merge_conditions(conditions, ["LOWER(#{active_scaffold_config.columns[key].search_sql}) LIKE ?", like_pattern.sub(/\?/, value.downcase)])
          end
        end        
        self.active_scaffold_conditions = conditions

        includes_for_search_columns = columns.collect{ |column| column.includes}.flatten.uniq.compact
        self.active_scaffold_joins.concat includes_for_search_columns

        active_scaffold_config.list.user.page = nil
      end
    end
  end
end
