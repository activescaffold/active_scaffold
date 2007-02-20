module ActiveScaffold::Actions
  module Core
    def self.included(base)
      base.class_eval do
        after_filter :clear_flashes
        before_filter :association_filter, :only => [:create, :update]
      end
    end

    # Provide validation and template for displaying association in list
    # TODO How to handle associations on the association?
    def add_association
      @association = active_scaffold_config.model.reflect_on_association(params[:id].to_sym)
      @record_params = params[@association.klass.to_s.underscore]

      # Create a new object or find based on what params are available
      @record = @record_params[:id].nil? ? @association.klass.new(@record_params) : @association.klass.find(@record_params[:id])
      render(:action => 'add_association', :layout => false)
    end

    protected

    # Initialize all non-singular associations to be empty if not defined by the form
    # TODO Big problem here... if you don't have all elements on the form then those hidden
    #      attributes will be deleted every time... We should only be initializing the xxx_ids=
    #      methods for those associations that are actually in create.columns
    def association_filter
      associations = [:has_many, :has_and_belongs_to_many].collect { |type| active_scaffold_config.model.reflect_on_all_associations(type) }.flatten
      associations.each do |association|
        unless params[:record].nil? || params[:record].empty?
          params[:record]["#{association.name.to_s.singularize}_ids"] ||= []
        end
      end
    end

    def build_associations(record)
      unless params[:_associations].nil? || params[:_associations].empty?
        associations_params = params[:_associations]
        associations_params.each do |association_name, values|
          association = active_scaffold_config.model.reflect_on_association(association_name.to_sym)

          if [:has_one, :belongs_to].include? association.macro
            values.each { |temp, attributes| record.method("build_#{association_name}").call(attributes) }
          else
            values.each { |temp, attributes| record.send(association_name).build(attributes) }
          end
        end
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

    def conditions_from_params
      conditions = nil
      params.reject {|key, value| [:controller, :action, :id].include?(key.to_sym)}.each do |key, value|
        next unless active_scaffold_config.model.column_names.include?(key)
        conditions = merge_conditions(conditions, ["#{key.to_s} = ?", value])
        if key.include?('_id')
          active_scaffold_config.label << " for " + eval("#{key.gsub('_id', '').camelize.constantize}.find(value).to_label")
          params[:nested_active_scaffold_id_name] = key
          params[:nested_active_scaffold_id] = value
        end
      end
      conditions
    end
  end
end