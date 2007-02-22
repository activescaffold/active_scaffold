module ActiveScaffold::Actions
  module Core
    def self.included(base)
      base.class_eval do
        after_filter :clear_flashes
      end
    end

    # Provides validation and template for displaying association in sub-list
    def add_association
      @association = active_scaffold_config.model.reflect_on_association(params[:id].to_sym)
      @record = find_or_create_for_params(params[@association.klass.to_s.underscore], @association.klass)

      render(:action => 'add_association', :layout => false)
    end

    protected

    # Finds or creates ActiveRecord objects for the associations params (derived from the request
    # params using split_record_params) and tacks them onto the given parent AR model.
    def build_associations(parent_record, associations_params = {})
      return if associations_params.empty?

      associations_params.each do |association_name, values|
        association = parent_record.class.reflect_on_association(association_name.to_sym)

        if [:has_one, :belongs_to].include? association.macro
          record_params = values
          record = find_or_create_for_params(record_params, association.klass)
          eval "parent_record.#{association.name} = record" unless record.nil?
        else
          records = values.values.collect do |record_params|
            find_or_create_for_params(record_params, association.klass)
          end.compact rescue []
          eval "parent_record.#{association.name} = records"
        end
      end
    end

    # Attempts to create or find an instance of klass (which must be an ActiveRecord object) from the
    # request parameters given. If params[:id] exists it will attempt to find an existing object
    # otherwise it will build a new one.
    def find_or_create_for_params(params, klass)
      return nil if params.empty?

      record = nil
      if params.has_key? :id
        record = klass.find(params[:id]) unless params[:id].empty?
      else
        # TODO We need some security checks in here so we don't create new objects when you are not authorized
        attribute_params, associations_params = split_record_params(params,klass)
        record = klass.new(attribute_params)
        build_associations(record, associations_params) unless associations_params.empty?
      end
      record
    end

    # Splits a params hash into two hashes: one of all values that map to an attribute on the given class (klass)
    # and one all the values that map to associations (belongs_to, has_many, etc) on the class.
    def split_record_params(params, klass)
      attribute_params, associations_params = params.dup, {}
      klass.reflect_on_all_associations.each do |association|
        if attribute_params.has_key?(association.name)
          value = attribute_params.delete(association.name)
          associations_params[association.name] = value
        end
      end
      return attribute_params, associations_params
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