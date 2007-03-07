module ActiveScaffold::Actions
  module Core
    def self.included(base)
      base.class_eval do
        after_filter :clear_flashes
      end
    end

    protected

    def record_allowed_for_action?(record, action)
      current_user = self.send(active_scaffold_config.current_user_method) rescue nil
      security_method = "#{action}_authorized?"
      return (record.respond_to?(security_method) and current_user) ? record.send(security_method, current_user) : true
    end

    # Takes attributes (as from params[:record]) and applies them to the parent_record. Also looks for
    # association attributes and attempts to instantiate them as associated objects.
    #
    # This is a secure way to apply params to a record, because it's based on a loop over the columns
    # set. The columns set will not yield unauthorized columns, and it will not yield unregistered columns.
    # this very effectively replaces the params[:record] filtering i set up before.
    def update_record_from_params(parent_record, columns, attributes)
      return parent_record unless parent_record.new_record? or record_allowed_for_action?(parent_record, 'update')

      columns.each :flatten => true do |column|
        next unless attributes.has_key? column.name
        value = attributes[column.name]

        # convert the value, possibly by instantiating associated objects
        value = if column.singular_association? and column.ui_type == :select
          column.association.klass.find(value)

        elsif column.singular_association?
          hash = value
          record = find_or_create_for_params(hash, column.association.klass)
          if record
            record_columns = active_scaffold_config_for(column.association.klass).subform.columns
            update_record_from_params(record, record_columns, hash)
          end
          record

        elsif column.plural_association?
          collection = value.collect do |key_value_pair|
            hash = key_value_pair[1]
            record = find_or_create_for_params(hash, column.association.klass)
            if record
              record_columns = active_scaffold_config_for(column.association.klass).subform.columns
              update_record_from_params(record, record_columns, hash)
            end
            record
          end
          collection.compact

        else
          value
        end

        parent_record.send("#{column.name}=", value)
      end
      parent_record
    end

    # Attempts to create or find an instance of klass (which must be an ActiveRecord object) from the
    # request parameters given. If params[:id] exists it will attempt to find an existing object
    # otherwise it will build a new one.
    def find_or_create_for_params(params, klass)
      return nil if params.all? {|k, v| v.empty?}

      if params.has_key? :id
        return klass.find(params[:id])
      else
        # TODO check that user is authorized to create a record of this klass
        return klass.new
      end
    end

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