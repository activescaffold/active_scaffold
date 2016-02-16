module ActiveScaffold::Actions
  module Update
    def self.included(base)
      base.before_filter :update_authorized_filter, :only => [:edit, :update]
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
        render(:action => 'update')
      else
        return_to_main
      end
    end

    def edit_respond_to_js
      render(:partial => 'update_form')
    end

    def update_respond_to_html
      if params[:iframe] == 'true' # was this an iframe post ?
        do_refresh_list if successful? && active_scaffold_config.update.refresh_list && !render_parent?
        responds_to_parent do
          render :action => 'on_update', :formats => [:js], :layout => false
        end
      else # just a regular post
        if successful?
          message = as_(:updated_model, :model => ERB::Util.h(@record.to_label))
          if params[:dont_close]
            flash.now[:info] = message
            render(:action => 'update')
          else
            flash[:info] = message
            return_to_main
          end
        else
          render(:action => 'update')
        end
      end
    end

    def update_respond_to_js
      if successful?
        if !render_parent? && active_scaffold_config.actions.include?(:list)
          if update_refresh_list?
            do_refresh_list
          else
            @updated_record = @record
            # get_row so associations are cached like in list action
            @record = get_row rescue nil # if record doesn't fullfil current conditions remove it from list
          end
        end
        flash.now[:info] = as_(:updated_model, :model => ERB::Util.h((@updated_record || @record).to_label)) if active_scaffold_config.update.persistent
      end
      render :action => 'on_update'
    end

    def update_respond_to_xml
      render :xml => response_object, :only => update_columns_names + [active_scaffold_config.model.primary_key], :include => association_columns(update_columns_names), :methods => virtual_columns(update_columns_names), :status => response_status
    end

    def update_respond_to_json
      render :json => response_object, :only => update_columns_names + [active_scaffold_config.model.primary_key], :include => association_columns(update_columns_names), :methods => virtual_columns(update_columns_names), :status => response_status
    end

    def update_columns_names
      active_scaffold_config.update.columns.names
    end

    # A simple method to find and prepare a record for editing
    # May be overridden to customize the record (set default values, etc.)
    def do_edit
      @record = find_if_allowed(params[:id], :update)
    end

    # A complex method to update a record. The complexity comes from the support for subforms, and saving associated records.
    # If you want to customize this algorithm, consider using the +before_update_save+ callback
    def do_update
      do_edit
      update_save
    end

    def update_save(options = {})
      attributes = options[:attributes] || params[:record]
      begin
        active_scaffold_config.model.transaction do
          @record = update_record_from_params(@record, active_scaffold_config.update.columns, attributes) unless options[:no_record_param_update]
          before_update_save(@record)
          # errors to @record can be added by update_record_from_params when association fails to set and ActiveRecord::RecordNotSaved is raised
          self.successful = [@record.keeping_errors { @record.valid? }, @record.associated_valid?].all? # this syntax avoids a short-circuit
          if successful?
            @record.save! && @record.save_associated!
            after_update_save(@record)
          else
            # some associations such as habtm are saved before saved is called on parent object
            # we have to revert these changes if validation fails
            raise ActiveRecord::Rollback, "don't save habtm associations unless record is valid"
          end
        end
      rescue ActiveRecord::StaleObjectError
        @record.errors.add(:base, as_(:version_inconsistency))
        self.successful = false
      rescue ActiveRecord::RecordNotSaved => exception
        logger.warn do
          "\n\n#{exception.class} (#{exception.message}):\n    " +
            Rails.backtrace_cleaner.clean(exception.backtrace).join("\n    ") +
            "\n\n"
        end
        @record.errors.add(:base, as_(:record_not_saved)) if @record.errors.empty?
        self.successful = false
      rescue ActiveRecord::ActiveRecordError => ex
        flash[:error] = ex.message
        self.successful = false
      end
    end

    def do_update_column
      # delete from params so update :table won't break urls, also they shouldn't be used in sort links too
      value = params.delete(:value)
      column = params.delete(:column).to_sym
      params.delete(:original_html)
      params.delete(:original_value)
      @column = active_scaffold_config.columns[column]
      @record = find_if_allowed(params[:id], :read)
      return unless @record.authorized_for?(:crud_type => :update, :column => column)

      value ||=
        unless @column.column.nil? || @column.column.null
          default_val = @column.column.default
          default_val = @column.column.cast_type.type_cast_from_user default_val if Rails.version >= '4.2.0'
          default_val == true ? false : default_val
        end
      unless @column.nil?
        value = column_value_from_param_value(@record, @column, value)
        value = [] if value.nil? && @column.form_ui && @column.plural_association?
      end

      @record.send("#{@column.name}=", value)
      before_update_save(@record)
      self.successful = @record.save
      if self.successful? && active_scaffold_config.actions.include?(:list)
        if @column.inplace_edit_update == :table
          params.delete(:id)
          do_list
        elsif @column.inplace_edit_update
          get_row
        end
      end
      after_update_save(@record)
    end

    # override this method if you want to inject data in the record (or its associated objects) before the save
    def before_update_save(record); end

    # override this method if you want to do something after the save
    def after_update_save(record); end

    # should we refresh whole list after update operation
    def update_refresh_list?
      active_scaffold_config.update.refresh_list
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def update_authorized?(record = nil)
      (!nested? || !nested.readonly?) && (record || self).authorized_for?(:crud_type => :update)
    end

    def update_ignore?(record = nil)
      !self.authorized_for?(:crud_type => :update)
    end

    private

    def update_authorized_filter
      link = active_scaffold_config.update.link || active_scaffold_config.update.class.link
      raise ActiveScaffold::ActionNotAllowed unless send(link.security_method)
    end

    def edit_formats
      (default_formats + active_scaffold_config.formats).uniq
    end

    def update_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.update.formats).uniq
    end
  end
end
