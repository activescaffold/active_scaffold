module ActiveScaffold::Actions
  module Create
    include Base

    def self.included(base)
      super
      base.verify :method => :post,
                  :only => :create,
                  :redirect_to => { :action => :index }
    end

    def new
      return unless insulate { do_new }

      respond_to do |type|
        type.html do
          if successful?
            render(:action => 'create_form', :layout => true)
          else
            return_to_main
          end
        end
        type.js do
          render(:partial => 'create_form', :layout => false)
        end
      end
    end

    def create
      return unless insulate { do_create }

      respond_to do |type|
        type.html do
          if successful?
            flash[:info] = _('CREATED %s', @record.to_label)
            return_to_main
          else
            render(:action => 'create_form', :layout => true)
          end
        end
        type.js do
          if successful?
            render :action => 'create', :layout => false
          else
            render :action => 'form_messages.rjs', :layout => false
          end
        end
        type.xml { render :xml => response_object.to_xml, :content_type => Mime::XML, :status => response_status }
        type.json { render :text => response_object.to_json, :content_type => Mime::JSON, :status => response_status }
        type.yaml { render :text => response_object.to_yaml, :content_type => Mime::YAML, :status => response_status }
      end
    end

    protected

    def do_new
      @record = active_scaffold_config.model.new
    end

    def do_create
      active_scaffold_config.model.transaction do
        @record = update_record_from_params(active_scaffold_config.model.new, active_scaffold_config.create.columns, params[:record])
        active_scaffold_constraints.each { |k, v| @record.send("#{k}=", v) } unless active_scaffold_association_macro == :has_and_belongs_to_many
        before_create_save(@record)
        @record.save! and @record.save_associated!
        if active_scaffold_association_macro == :has_and_belongs_to_many
          params[:associated_id] = @record
          do_add_existing 
        end
      end
    end

    # override this method if you want to interject data in the @record (or its associated objects) before the save
    def before_create_save(record); end
  end
end
