module ActiveScaffold::Actions
  module Update
    include Base

    def self.included(base)
      super
      base.verify :method => :post,
                  :only => :update,
                  :redirect_to => { :action => :index }
    end

    def edit
      insulate { do_edit }

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
      insulate { do_update }

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
            render :update do |page|
              page << "$('#{action_link_id(:action => active_scaffold_config.update.link.action)}').action_link.close_with_refresh()"
            end
          else
            render :update do |page|
              page.replace_html element_messages_id(:action => :update), :partial => 'form_messages'
            end
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
      build_associations(@record)
      @record.update_attributes(params[:record])
    end
  end
end