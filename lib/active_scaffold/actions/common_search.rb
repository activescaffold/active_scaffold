module ActiveScaffold::Actions
  module CommonSearch
    protected
    def store_search_params_into_session
      if active_scaffold_config.store_user_settings
        active_scaffold_session_storage[:search] = params.delete :search if params[:search]
      else
        @search_params = params.delete :search
      end
    end

    def search_params
      @search_params || active_scaffold_session_storage[:search]
    end

    def search_ignore?
      active_scaffold_config.list.always_show_search
    end
    
    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def search_authorized?
      authorized_for?(:crud_type => :read)
    end
  end
end
