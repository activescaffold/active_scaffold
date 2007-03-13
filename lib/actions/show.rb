module ActiveScaffold::Actions
  module Show
    include ActiveScaffold::Actions::Base
    def show
      return unless insulate { do_show }

      @successful = successful?
      respond_to do |type|
        type.html { render :action => 'show', :layout => true }
        type.js { render :partial => 'show', :layout => false }
        type.xml { render :xml => response_object.to_xml, :content_type => Mime::XML, :status => response_status }
        type.json { render :text => response_object.to_json, :content_type => Mime::JSON, :status => response_status }
        type.yaml { render :text => response_object.to_yaml, :content_type => Mime::YAML, :status => response_status }
      end
    end

    protected

    def do_show
      @record = find_if_allowed(params[:id], 'show')
    end
  end
end