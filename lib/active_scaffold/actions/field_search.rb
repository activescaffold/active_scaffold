module ActiveScaffold::Actions
  module FieldSearch
    def self.included(base)
      base.helper_method :field_search_params
      base.send :include, ActiveScaffold::Actions::CommonSearch
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      # FieldSearch uses params[:search] and not @record because search conditions do not always pass the Model's validations.
      # This facilitates for example, textual searches against associations via .search_sql
      def show_search
        @record = new_model
        super
      end

      protected

      def search_partial
        super || :field_search
      end

      def store_search_params_into_session
        set_field_search_default_params(active_scaffold_config.field_search.default_params) unless active_scaffold_config.field_search.default_params.nil?
        super
      end

      def set_field_search_default_params(default_params)
        return unless (params[:search].is_a?(String) || search_params.nil?) && params[:search].blank?
        params[:search] = default_params.is_a?(Proc) ? instance_eval(&default_params) : default_params
      end

      def field_search_params
        search_params.is_a?(Hash) ? search_params : {}
      end

      def field_search_respond_to_html
        render(:action => 'field_search')
      end

      def field_search_respond_to_js
        render(:partial => 'field_search')
      end

      def do_search
        if search_params.is_a?(Hash) && search_params.present?
          filtered_columns = []
          text_search = active_scaffold_config.field_search.text_search
          columns = active_scaffold_config.field_search.columns
          count_includes = active_scaffold_config.list.user.count_includes
          search_params.each do |key, value|
            next unless columns.include? key
            column = active_scaffold_config.columns[key]
            search_condition = self.class.condition_for_column(column, value, text_search)
            next if search_condition.blank?

            if count_includes.nil? && column.includes.present? && list_columns.include?(column)
              active_scaffold_references << column.includes
            elsif column.search_joins.present?
              active_scaffold_outer_joins << column.search_joins
            end
            active_scaffold_conditions << search_condition
            filtered_columns << column
          end
          unless filtered_columns.blank?
            @filtered = active_scaffold_config.field_search.human_conditions ? filtered_columns : true
          end

          active_scaffold_config.list.user.page = nil
        else
          super
        end
      end

      def field_search_ignore?
        active_scaffold_config.list.always_show_search && active_scaffold_config.list.search_partial == 'field_search'
      end

      private

      def field_search_formats
        (default_formats + active_scaffold_config.formats + active_scaffold_config.field_search.formats).uniq
      end
    end
  end
end
