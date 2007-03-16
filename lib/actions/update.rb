module ActiveScaffold::Actions
  module Update
    include Base

    def self.included(base)
      super
      base.verify :method => [:post, :put],
                  :only => :update,
                  :redirect_to => { :action => :index }
    end

    def edit
      return unless insulate { do_edit }

      respond_to do |type|
        type.html do
          if successful?
            render(:action => 'update_form', :layout => true)
          else
            return_to_main
          end
        end
        type.js do
          render(:partial => 'update_form', :layout => false)
        end
      end
    end

    def update
      return unless insulate { do_update }

      respond_to do |type|
        type.html do
          if successful?
            flash[:info] = _('UPDATED %s', @record.to_label)
            return_to_main
          else
            render(:action => 'update_form', :layout => true)
          end
        end
        type.js do
          if successful?
            render :action => 'update.rjs', :layout => false
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

    def do_edit
      @record = find_if_allowed(params[:id], 'update')
    end

    def do_update
      @record = find_if_allowed(params[:id], 'update')
      begin
        active_scaffold_config.model.transaction do
          @record = update_record_from_params(@record, active_scaffold_config.update.columns, params[:record])
          before_update_save(@record)
          @record.save! and @record.save_associated!
        end
      rescue ActiveRecord::RecordInvalid
      end
    end

    # override this method if you want to interject data in the @record (or its associated objects) before the save
    def before_update_save(record); end
  end
end