module ActiveScaffold::Actions
  module List
    include ActiveScaffold::Actions::Base

    def index
      list
    end

    def table
      do_list
      render(:action => 'list', :layout => false)
    end

    # This is called when changing pages, sorts and search
    def update_table
      respond_to do |type|
        type.js do
          do_list
          render(:partial => 'list', :layout => false)
        end
        type.html { return_to_main }
      end
    end

    # get just a single row
    def row
      render :partial => 'list_record', :locals => {:record => find_if_allowed(params[:id], 'list')}
    end

    def list
      return unless insulate { do_list }

      respond_to do |type|
        type.html {
          render :action => 'list', :layout => true
        }
        type.xml { render :xml => response_object.to_xml, :content_type => Mime::XML, :status => response_status }
        type.json { render :text => response_object.to_json, :content_type => Mime::JSON, :status => response_status }
        type.yaml { render :text => response_object.to_yaml, :content_type => Mime::YAML, :status => response_status }
      end
    end

    protected

    def do_list
      includes_for_list_columns = active_scaffold_config.list.columns.collect{ |c| c.includes }.flatten.uniq.compact
      self.active_scaffold_joins.concat includes_for_list_columns

      options = {}
      if accepts? :html, :js
        options = { :sorting => active_scaffold_config.list.user.sorting,
                    :per_page => active_scaffold_config.list.user.per_page,
                    :page => active_scaffold_config.list.user.page }
      end

      @page = find_page(options)
      @records = @page.items
    end
  end
end