module ActiveScaffold::Actions
  module Show
    def self.included(base)
      base.before_filter :show_authorized_filter, :only => :show
    end

    def show
      # rest destroy falls back to rest show in case of disabled javascript
      # just render action_confirmation message for destroy
      if params.delete :destroy_action
        @record = find_if_allowed(params[:id], :read) if params[:id]
        action_confirmation_respond_to_html(:destroy)
      else
        do_show
        respond_to_action(:show)
      end
    end

    protected

    def show_respond_to_json
      render :json => response_object, :only => show_columns_names + [active_scaffold_config.model.primary_key], :include => association_columns(show_columns_names), :methods => virtual_columns(show_columns_names), :status => response_status
    end

    def show_respond_to_xml
      render :xml => response_object, :only => show_columns_names + [active_scaffold_config.model.primary_key], :include => association_columns(show_columns_names), :methods => virtual_columns(show_columns_names), :status => response_status
    end

    def show_respond_to_js
      render :partial => 'show'
    end

    def show_respond_to_html
      render :action => 'show'
    end

    def show_columns_names
      active_scaffold_config.show.columns.names
    end

    # A simple method to retrieve and prepare a record for showing.
    # May be overridden to customize show routine
    def do_show
      set_includes_for_columns(:show) if active_scaffold_config.actions.include? :list
      klass = beginning_of_chain.preload(active_scaffold_preload)
      @record = find_if_allowed(params[:id], :read, klass)
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def show_authorized?(record = nil)
      (record || self).send(:authorized_for?, :crud_type => :read)
    end

    def show_ignore?(record = nil)
      !send(:authorized_for?, :crud_type => :read)
    end

    private

    def show_authorized_filter
      link = active_scaffold_config.show.link || active_scaffold_config.show.class.link
      raise ActiveScaffold::ActionNotAllowed unless send(link.security_method)
    end

    def show_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.show.formats).uniq
    end
  end
end
