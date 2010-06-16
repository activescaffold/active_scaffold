module ActiveScaffold::Actions
  module CommonSearch
    protected
    def store_search_params_into_session
      active_scaffold_session_storage[:search] = params.delete :search if params[:search]
    end
    
    def search_params
      active_scaffold_session_storage[:search]
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def search_authorized?
      if active_scaffold_config.list.always_show_search
        false
      else
        authorized_for?(:crud_type => :read)
      end
    end
  end
end
