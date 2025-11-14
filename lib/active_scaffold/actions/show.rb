# frozen_string_literal: true

module ActiveScaffold::Actions
  module Show
    def self.included(base)
      base.before_action :show_authorized_filter, only: :show
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
      response_to_api(:json, show_columns_names)
    end

    def show_respond_to_xml
      response_to_api(:xml, show_columns_names)
    end

    def show_respond_to_js
      render partial: 'show'
    end

    def show_respond_to_html
      render action: 'show'
    end

    def show_columns_names
      active_scaffold_config.show.columns.visible_columns_names
    end

    # A simple method to retrieve and prepare a record for showing.
    # May be overridden to customize show routine
    def do_show
      set_includes_for_columns(:show) if active_scaffold_config.actions.include? :list
      get_row
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def show_authorized?(record = nil)
      (record || self).authorized_for?(crud_type: :read, reason: true)
    end

    def show_ignore?(record = nil)
      !send(:authorized_for?, crud_type: :read)
    end

    private

    def show_authorized_filter
      link = active_scaffold_config.show.link || self.class.active_scaffold_config.show.class.link
      raise ActiveScaffold::ActionNotAllowed unless action_link_authorized?(link)
    end

    def show_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.show.formats).uniq
    end
  end
end
