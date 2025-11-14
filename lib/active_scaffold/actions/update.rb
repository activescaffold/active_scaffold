# frozen_string_literal: true

module ActiveScaffold::Actions
  module Update
    def self.included(base)
      base.before_action :update_authorized_filter, only: %i[edit update]
      base.helper_method :update_refresh_list?
    end

    def edit
      do_edit
      respond_to_action(:edit)
    end

    def update
      do_update
      respond_to_action(:update)
    end

    # for inline (inlist) editing
    def update_column
      do_update_column
      @column_span_id = params.delete(:editor_id) || params.delete(:editorId)
    end

    protected

    def edit_respond_to_html
      if successful?
        render action: 'update'
      else
        return_to_main
      end
    end

    def edit_respond_to_js
      render partial: 'update_form'
    end

    def update_respond_on_iframe
      do_refresh_list if successful? && active_scaffold_config.update.refresh_list && !render_parent?
      responds_to_parent do
        render action: 'on_update', formats: [:js], layout: false
      end
    end

    def update_respond_to_html
      if successful? # just a regular post
        message = as_(:updated_model, model: ERB::Util.h(@record.to_label))
        if params[:dont_close]
          flash.now[:info] = message
          render action: 'update'
        else
          flash[:info] = message
          return_to_main
        end
      else
        render action: 'update'
      end
    end

    def record_to_refresh_on_update
      if update_refresh_list?
        do_refresh_list
      else
        reload_record_on_update
      end
    end

    def reload_record_on_update
      @updated_record = @record
      # get_row so associations are cached like in list action
      # if record doesn't fullfil current conditions remove it from list
      get_row
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def update_respond_to_js
      if successful?
        record_to_refresh_on_update if !render_parent? && active_scaffold_config.actions.include?(:list)
        flash.now[:info] = as_(:updated_model, model: ERB::Util.h((@updated_record || @record).to_label)) if active_scaffold_config.update.persistent
      end
      render action: 'on_update'
    end

    def update_respond_to_xml
      response_to_api(:xml, update_columns_names)
    end

    def update_respond_to_json
      response_to_api(:json, update_columns_names)
    end

    def update_columns_names
      active_scaffold_config.update.columns.visible_columns_names
    end

    # A simple method to find and prepare a record for editing
    # May be overridden to customize the record (set default values, etc.)
    def do_edit
      preload_values = preload_for_form(active_scaffold_config.update.columns)
      @record = find_if_allowed(params[:id], :update, filtered_query.preload(preload_values))
    end

    # A complex method to update a record. The complexity comes from the support for subforms,
    # and saving associated records.
    # If you want to customize this algorithm, consider using the +before_update_save+ callback
    def do_update
      do_edit
      update_save
    end

    def update_save(attributes: params[:record], no_record_param_update: false)
      active_scaffold_config.model.transaction do
        unless no_record_param_update
          @record = update_record_from_params(@record, active_scaffold_config.update.columns, attributes)
        end
        before_update_save(@record)
        # errors to @record can be added by update_record_from_params when association fails
        # to set and ActiveRecord::RecordNotSaved is raised
        # this syntax avoids a short-circuit, so we run validations on record and associations
        self.successful = [@record.keeping_errors { @record.valid? }, @record.associated_valid?].all?

        unless successful?
          # some associations such as habtm are saved before saved is called on parent object
          # we have to revert these changes if validation fails
          raise ActiveRecord::Rollback, "don't save habtm associations unless record is valid"
        end

        @record.save! && @record.save_associated!
        after_update_save(@record)
      end
    rescue ActiveRecord::StaleObjectError
      @record.errors.add(:base, as_(:version_inconsistency))
      self.successful = false
      on_stale_object_error(@record)
    rescue ActiveRecord::RecordNotSaved => e
      logger.warn do
        "\n\n#{e.class} (#{e.message}):\n    #{Rails.backtrace_cleaner.clean(e.backtrace).join("\n    ")}\n\n"
      end
      @record.errors.add(:base, as_(:record_not_saved)) if @record.errors.empty?
      self.successful = false
    rescue ActiveRecord::ActiveRecordError => e
      flash[:error] = e.message
      self.successful = false
    end

    def do_update_column
      # delete from params so update :table won't break urls, also they shouldn't be used in sort links too
      value = params.delete(:value)
      column = params.delete(:column)
      params.delete(:original_html)
      params.delete(:original_value)
      @column = active_scaffold_config.columns[column]

      value_record = record_for_update_column
      value = value_for_update_column(value, @column, value_record)
      value_record.send(:"#{@column.name}=", value)
      before_update_save(@record)
      self.successful = value_record.save
      if !successful?
        flash.now[:error] = value_record.errors.full_messages.presence
      elsif active_scaffold_config.actions.include?(:list)
        if @column.inplace_edit_update == :table
          params.delete(:id)
          do_list
        elsif @column.inplace_edit_update
          get_row
        end
      end
      after_update_save(@record)
    rescue ActiveScaffold::ActionNotAllowed
      self.successful = false
    end

    def record_for_update_column
      @record = find_if_allowed(params[:id], :read)
      raise ActiveScaffold::ActionNotAllowed unless @record.authorized_for?(crud_type: :update, column: @column.name)

      if @column.delegated_association
        value_record = @record.send(@column.delegated_association.name)
        value_record ||= @record.association(@column.delegated_association.name).build
        raise ActiveScaffold::ActionNotAllowed unless value_record.authorized_for?(crud_type: :update, column: @column.name)

        value_record
      else
        @record
      end
    end

    def value_for_update_column(param_value, column, record)
      unless param_value
        param_value = column.default_for_empty_value
        param_value = false if param_value == true
      end
      value = column_value_from_param_value(record, column, param_value)
      value = [] if value.nil? && column.form_ui && column.association&.collection?
      value
    end

    # override this method if you want to inject data in the record (or its associated objects) before the save
    def before_update_save(record); end

    # override this method if you want to do something after the save
    def after_update_save(record); end

    # override this method if you want to do something when stale object error is raised
    def on_stale_object_error(record); end

    # should we refresh whole list after update operation
    def update_refresh_list?
      active_scaffold_config.update.refresh_list
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def update_authorized?(record = nil, column = nil)
      (!nested? || !nested.readonly?) && (record || self).authorized_for?(crud_type: :update, column: column, reason: true)
    end

    def update_ignore?(record = nil)
      !authorized_for?(crud_type: :update)
    end

    private

    def update_authorized_filter
      link = active_scaffold_config.update.link || self.class.active_scaffold_config.update.class.link
      raise ActiveScaffold::ActionNotAllowed unless action_link_authorized?(link)
    end

    def edit_formats
      (default_formats + active_scaffold_config.formats).uniq
    end

    def update_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.update.formats).uniq
    end
  end
end
