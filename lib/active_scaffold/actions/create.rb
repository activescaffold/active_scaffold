# frozen_string_literal: true

module ActiveScaffold::Actions
  module Create
    def self.included(base)
      base.before_action :create_authorized_filter, only: %i[new create]
    end

    def new
      do_new
      respond_to_action(:new)
    end

    def create
      do_create
      respond_to_action(:create)
    end

    protected

    def response_location
      url_for(params_for(action: 'show', id: @record.to_param)) if successful?
    end

    def new_respond_to_html
      if successful?
        render(action: 'create')
      else
        return_to_main
      end
    end

    def new_respond_to_js
      render(partial: 'create_form')
    end

    def create_respond_on_iframe
      do_refresh_list if successful? && active_scaffold_config.create.refresh_list && !render_parent?
      responds_to_parent do
        render action: 'on_create', formats: [:js], layout: false
      end
    end

    def create_respond_to_html
      if successful?
        flash[:info] = as_(:created_model, model: ERB::Util.h(@record.to_label))
        if (action = active_scaffold_config.create.action_after_create)
          redirect_to params_for(action: action, id: @record.to_param)
        elsif params[:dont_close]
          redirect_to params_for(action: 'new')
        else
          return_to_main
        end
      elsif active_scaffold_config.actions.include?(:list) && active_scaffold_config.list.always_show_create
        list
      else
        render(action: 'create')
      end
    end

    def create_respond_to_js
      if successful? && !render_parent?
        do_refresh_list if active_scaffold_config.create.refresh_list
        if params[:dont_close]
          @saved_record = @record
          do_new
        end
      end
      render action: 'on_create'
    end

    def create_respond_to_xml
      response_to_api(:xml, create_columns_names, location: response_location)
    end

    def create_respond_to_json
      response_to_api(:json, create_columns_names, location: response_location)
    end

    def create_columns_names
      active_scaffold_config.create.columns.visible_columns_names
    end

    # A simple method to find and prepare an example new record for the form
    # May be overridden to customize the behavior (add default values, for instance)
    def do_new
      @record = new_model
      apply_constraints_to_record(@record)
      create_association_with_parent(@record) if nested?
      @record
    end

    # A somewhat complex method to actually create a new record. The complexity is from support for subforms and associated records.
    # If you want to customize this behavior, consider using the +before_create_save+ and +after_create_save+ callbacks.
    def do_create(options = {})
      attributes = options[:attributes] || params[:record]
      active_scaffold_config.model.transaction do
        @record = new_model
        # before assign params, to set foreign_type of constraints in polymorphic association with multiple id
        apply_constraints_to_record(@record, allow_autosave: true)
        @record = update_record_from_params(@record, active_scaffold_config.create.columns, attributes)
        create_association_with_parent(@record) if nested?
        before_create_save(@record)
        # errors to @record can be added by update_record_from_params when association fails to set and ActiveRecord::RecordNotSaved is raised
        self.successful = [@record.keeping_errors { @record.valid? }, @record.associated_valid?].all? # this syntax avoids a short-circuit
        create_save(@record) unless options[:skip_save]
      end
    rescue ActiveRecord::ActiveRecordError => e
      flash[:error] = e.message
      self.successful = false
      @record ||= new_model # ensure @record exists or display form will fail
    end

    def create_save(record)
      return unless successful?

      record.save! && record.save_associated!
      after_create_save(record)
    end

    # override this method if you want to inject data in the record (or its associated objects) before the save
    def before_create_save(record); end

    # override this method if you want to do something after the save
    def after_create_save(record); end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.

    def create_ignore?
      active_scaffold_config.list.always_show_create
    end

    def create_authorized?
      if nested? && (nested.readonly? || nested.readonly_through_association?(active_scaffold_config.create.columns))
        return false
      end

      authorized_for?(crud_type: :create)
    end

    private

    def create_authorized_filter
      link = active_scaffold_config.create.link || self.class.active_scaffold_config.create.class.link
      raise ActiveScaffold::ActionNotAllowed unless action_link_authorized?(link)
    end

    def new_formats
      (default_formats + active_scaffold_config.formats).uniq
    end

    def create_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.create.formats).uniq
    end
  end
end
