# frozen_string_literal: true

module ActiveScaffold::Actions
  module CommonSearch
    def self.included(base)
      return if base < InstanceMethods

      base.send :include, InstanceMethods
      base.before_action :search_authorized_filter, only: :show_search
      base.before_action :store_search_params_into_session, only: %i[index show_search]
      base.before_action :do_search, only: [:index]
      base.helper_method :search_params
    end

    module InstanceMethods
      def show_search
        respond_to_action(search_partial || :search)
      end

      protected

      def do_search; end

      def search_partial
        @_search_partial ||=
          if params[:kind].present? && active_scaffold_config.actions.include?(params[:kind])
            params.delete(:kind)
          else
            active_scaffold_config.list.auto_search_partial
          end
      end

      def permitted_search_params
        params_hash params[:search]
      end

      def set_outer_joins_for_search(columns) # rubocop:disable Naming/AccessorMethodName
        references = []
        outer_joins = []
        columns.each do |column|
          next if column.search_joins.blank?

          if column.includes.present? && list_columns.include?(column)
            references << (column.search_joins & column.includes)
            outer_joins << (column.search_joins - column.includes)
          else
            outer_joins << column.search_joins
          end
        end
        active_scaffold_references.concat references.flatten.uniq.compact
        active_scaffold_outer_joins.concat outer_joins.flatten.uniq.compact
      end

      def store_search_params_into_session
        if active_scaffold_config.store_user_settings
          if params[:search].present?
            active_scaffold_session_storage['search'] = permitted_search_params
          elsif params.key? :search
            active_scaffold_session_storage.delete 'search'
          end
        else
          @search_params = permitted_search_params
        end
        params.delete :search
      end

      def search_params
        @search_params || active_scaffold_session_storage['search'] unless params[:id]
      end

      # The default security delegates to ActiveRecordPermissions.
      # You may override the method to customize.
      def search_authorized?
        authorized_for?(crud_type: :read)
      end

      def search_authorized_filter
        action = active_scaffold_config.send(search_partial)
        link = action.link || action.class.link
        raise ActiveScaffold::ActionNotAllowed unless action_link_authorized?(link)
      end
    end
  end
end
