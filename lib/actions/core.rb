module ActiveScaffold::Actions
  module Core
    def self.included(base)
      base.class_eval do
        after_filter :clear_flashes
      end
    end

    protected

    def clear_flashes
      if request.xhr?
        flash.keys.each do |flash_key|
          flash[flash_key] = nil
        end
      end
    end

    # Wraps the given block to catch and handle exceptions.
    # Uses the overridable insulate? method to determine when to actually insulate.
    def insulate(&block)
      if insulate?
        begin
          yield
        rescue
          error_object = ActiveScaffold::DataStructures::ErrorMessage.new($!.to_s)

          respond_to do |type|
            type.html { return_to_main }
            type.js do
              flash[:error] = error_object.to_s;
              render :update do |page| # render page update
                page.replace_html active_scaffold_messages_id, :partial => 'messages'
              end
            end
            type.xml { render :xml => error_object.to_xml, :content_type => Mime::XML, :status => 500}
            type.json { render :text => error_object.to_json, :content_type => Mime::JSON, :status => 500}
            type.yaml { render :text => error_object.to_yaml, :content_type => Mime::YAML, :status => 500}
          end
        end
      else
        yield
      end
    end

    # Should the do_xxxxx call be wrapped by insulate to catch errors
    def insulate?
      !local_request?
    end

    # Returns true if the client accepts one of the MIME types passed to it
    # ex: accepts? :html, :xml
    def accepts?(*types)
      for priority in request.accepts.compact
        if priority == Mime::ALL
          # Because IE always sends */* in the accepts header and we assume
          # that if you really wanted XML or something else you would say so
          # explicitly, we will assume */* to only ask for :html
          return types.include?(:html)
        elsif types.include?(priority.to_sym)
          return true
        end
      end
      false
    end

    def response_status
      successful? ? 200 : 500
    end

    # API response object that will be converted to XML/YAML/JSON using to_xxx
    def response_object
      @response_object = successful? ? (@record || @records) : @record.errors
    end

    # We define success as having no errors in object.errors
    def successful?
      (@record.nil? || @record.errors.full_messages.empty?)
    end

    # Redirect to the main page (override if the ActiveScaffold is used as a component on another controllers page) for Javascript degradation
    def return_to_main
      redirect_to params.merge(:action => "index")
    end

    # Override this method on your controller to define conditions to be used when querying a recordset (e.g. for List). The return of this method should be any format compatible with the :conditions clause of ActiveRecord::Base's find.
    def conditions_for_collection
    end

    # Builds search conditions by search params for column names. This allows urls like "contacts/list?company_id=5".
    def conditions_from_params
      conditions = nil
      params.reject {|key, value| [:controller, :action, :id].include?(key.to_sym)}.each do |key, value|
        next unless active_scaffold_config.model.column_names.include?(key)
        conditions = merge_conditions(conditions, ["#{key.to_s} = ?", value])
      end
      conditions
    end

    # Builds search conditions based on the current scaffold constraints. This is used for embedded scaffolds (e.g. render :active_scaffold => 'users').
    def conditions_from_constraints
      conditions = nil
      active_scaffold_constraints.each do |k, v|
        conditions = merge_conditions(conditions, ["#{k.to_s} = ?", v])
      end
      conditions
    end
  end
end