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
      unless params[:record].nil?
        conditions = nil
        params[:record].each do |key, value|
          next unless active_scaffold_config.field_search.columns.include?(key) and !value.empty?
          case active_scaffold_config.columns[key].ui_type
          when :boolean, :integer
            conditions = merge_conditions(conditions, ["#{active_scaffold_config.columns[key].search_sql} = ?", "%#{value.downcase}%"])
          else
            conditions = merge_conditions(conditions, ["LOWER(#{active_scaffold_config.columns[key].search_sql}) LIKE ?", "%#{value.downcase}%"])
          end
        end
        self.active_scaffold_conditions = conditions

        includes_for_search_columns = active_scaffold_config.field_search.columns.collect{ |column| column.includes}.flatten.uniq.compact
        self.active_scaffold_includes.concat includes_for_search_columns

        active_scaffold_config.list.user.page = nil
      end
    end
  end
end
