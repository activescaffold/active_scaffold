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
      @column_span_id = params[:editor_id] || params[:editorId]
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
      if params[:iframe]=='true' # was this an iframe post ?
        responds_to_parent do
          render :action => 'on_update', :formats => [:js], :layout => false
        end
      else # just a regular post
        if successful?
          flash[:info] = as_(:updated_model, :model => @record.to_label)
          return_to_main
        else
          render(:action => 'update')
        end
      end
    end
    def update_respond_to_js
      if successful?
        do_refresh_list if update_refresh_list? && !render_parent?
        flash.now[:info] = as_(:updated_model, :model => @record.to_label) if active_scaffold_config.update.persistent
      end
      render :action => 'on_update'
    end
    def update_respond_to_xml
      render :xml => response_object.to_xml(:only => active_scaffold_config.update.columns.names), :content_type => Mime::XML, :status => response_status
    end
    def update_respond_to_json
      render :text => response_object.to_json(:only => active_scaffold_config.update.columns.names), :content_type => Mime::JSON, :status => response_status
    end
    def update_respond_to_yaml
      render :text => Hash.from_xml(response_object.to_xml(:only => active_scaffold_config.update.columns.names)).to_yaml, :content_type => Mime::YAML, :status => response_status
    end
    # A simple method to find and prepare a record for editing
    # May be overridden to customize the record (set default values, etc.)
    def do_edit
      set_includes_for_columns if active_scaffold_config.actions.include? :list
      klass = beginning_of_chain.includes(active_scaffold_includes)
      @record = find_if_allowed(params[:id], :update, klass)
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
          self.successful = [@record.valid?, @record.associated_valid?].all? # this syntax avoids a short-circuit
          if successful?
            @record.save! and @record.save_associated!
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
      rescue ActiveRecord::RecordNotSaved
        @record.errors.add(:base, as_(:record_not_saved)) if @record.errors.empty?
        self.successful = false
      rescue ActiveRecord::ActiveRecordError => ex
        flash[:error] = ex.message
        self.successful = false
      end
    end

    def do_update_column
      @record = find_if_allowed(params[:id], :read)
      if @record.authorized_for?(:crud_type => :update, :column => params[:column])
        @column = active_scaffold_config.columns[params[:column].to_sym]
        unless @column.column.nil? || @column.column.null
          if @column.column.default == true
            params[:value] ||= false
          else
            params[:value] ||= @column.column.default
          end
        end
        unless @column.nil?
          params[:value] = column_value_from_param_value(@record, @column, params[:value])
          params[:value] = [] if params[:value].nil? && @column.form_ui && @column.plural_association?
        end
        @record.send("#{@column.name}=", params[:value])
        before_update_save(@record)
        self.successful = @record.save
        do_list if self.successful? && @column.inplace_edit_update == :table
        after_update_save(@record)
      end
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
      (!nested? || !nested.readonly?) && (record || self).send(:authorized_for?, :crud_type => :update)
    end
    private
    def update_authorized_filter
      link = active_scaffold_config.update.link || active_scaffold_config.update.class.link
      raise ActiveScaffold::ActionNotAllowed unless self.send(link.security_method)
    end
    def edit_formats
      (default_formats + active_scaffold_config.formats).uniq
    end
    def update_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.update.formats).uniq
    end
  end
end
