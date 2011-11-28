module ActiveScaffold::Actions
  module Create
    def self.included(base)
      base.before_filter :create_authorized_filter, :only => [:new, :create]
      base.verify :method => :post,
                  :only => :create,
                  :redirect_to => { :action => :index }
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
      url_for(params_for(:action => "show", :id => @record.id)) if successful?
    end

    def new_respond_to_html
      if successful?
        render(:action => 'create')
      else
        return_to_main
      end
    end
    
    def new_respond_to_js
      render(:partial => 'create_form')
    end

    def create_respond_to_html
      if params[:iframe]=='true' # was this an iframe post ?
        responds_to_parent do
          render :action => 'on_create.js', :layout => false
        end
      else
        if successful?
          flash[:info] = as_(:created_model, :model => @record.to_label)
          if active_scaffold_config.create.action_after_create
            redirect_to params_for(:action => "edit", :id => @record.id)
          elsif active_scaffold_config.create.persistent
            redirect_to params_for(:action => "new")
          else
            return_to_main
          end
        else
          if !nested? && active_scaffold_config.actions.include?(:list) && active_scaffold_config.list.always_show_create
            do_list
            render(:action => 'list')
          else
            render(:action => 'create')
          end
        end
      end
    end

    def create_respond_to_js
      if successful? && active_scaffold_config.create.refresh_list && !render_parent?
        do_search if respond_to? :do_search
        do_list
      end
      render :action => 'on_create'
    end

    def create_respond_to_xml
      render :xml => response_object.to_xml(:only => active_scaffold_config.create.columns.names), :content_type => Mime::XML, :status => response_status, :location => response_location
    end

    def create_respond_to_json
      render :text => response_object.to_json(:only => active_scaffold_config.create.columns.names), :content_type => Mime::JSON, :status => response_status, :location => response_location
    end

    def create_respond_to_yaml
      render :text => Hash.from_xml(response_object.to_xml(:only => active_scaffold_config.create.columns.names)).to_yaml, :content_type => Mime::YAML, :status => response_status, :location => response_location
    end

    # A simple method to find and prepare an example new record for the form
    # May be overridden to customize the behavior (add default values, for instance)
    def do_new
      @record = new_model
      apply_constraints_to_record(@record)
      if nested?
        create_association_with_parent(@record)
        register_constraints_with_action_columns(nested.constrained_fields)
      end
      @record
    end

    # A somewhat complex method to actually create a new record. The complexity is from support for subforms and associated records.
    # If you want to customize this behavior, consider using the +before_create_save+ and +after_create_save+ callbacks.
    def do_create
      begin
        active_scaffold_config.model.transaction do
          @record = update_record_from_params(new_model, active_scaffold_config.create.columns, params[:record])
          apply_constraints_to_record(@record, :allow_autosave => true)
          if nested?
            create_association_with_parent(@record) 
            register_constraints_with_action_columns(nested.constrained_fields)
          end
          create_save
        end
      rescue ActiveRecord::RecordInvalid
      end
    end

    def create_save
      before_create_save(@record)
      self.successful = [@record.valid?, @record.associated_valid?].all? {|v| v == true} # this syntax avoids a short-circuit
      if successful?
        @record.save! and @record.save_associated!
        after_create_save(@record)
      end
    end

    # override this method if you want to inject data in the record (or its associated objects) before the save
    def before_create_save(record); end

    # override this method if you want to do something after the save
    def after_create_save(record); end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    
    def create_ignore?
      nested? && active_scaffold_config.list.always_show_create
    end
    
    def create_authorized?
      (!nested? || !nested.readonly?) && authorized_for?(:crud_type => :create)
    end
    private
    def create_authorized_filter
      link = active_scaffold_config.create.link || active_scaffold_config.create.class.link
      raise ActiveScaffold::ActionNotAllowed unless self.send(link.security_method)
    end
    def new_formats
      (default_formats + active_scaffold_config.formats).uniq
    end
    def create_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.create.formats).uniq
    end
  end
end
