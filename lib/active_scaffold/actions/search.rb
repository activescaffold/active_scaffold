# frozen_string_literal: true

module ActiveScaffold::Actions
  module Search
    def self.included(base)
      base.send :include, ActiveScaffold::Actions::CommonSearch
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      protected

      def search_respond_to_html
        render action: 'search'
      end

      def search_respond_to_js
        render partial: 'search'
      end

      def do_search
        if search_params.is_a?(String) && search_params.present?
          query = search_params.to_s.strip
          columns = active_scaffold_config.search.columns.visible_columns
          text_search = active_scaffold_config.search.text_search
          query = query.split(active_scaffold_config.search.split_terms) if active_scaffold_config.search.split_terms
          search_conditions = self.class.conditions_for_columns(query, columns, text_search)
          @filtered = search_conditions.present?
          active_scaffold_conditions.concat search_conditions if @filtered

          set_outer_joins_for_search columns
          active_scaffold_config.list.user.page = nil
        else
          super
        end
      end

      def search_ignore?
        active_scaffold_config.list.always_show_search && active_scaffold_config.list.search_partial == 'search'
      end

      private

      def search_formats
        (default_formats + active_scaffold_config.formats + active_scaffold_config.search.formats).uniq
      end
    end
  end
end
