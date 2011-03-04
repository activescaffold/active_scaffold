module ActiveScaffold::Actions
  module Core
    def self.included(base)
      base.class_eval do
        after_filter :clear_flashes
      end
      base.helper_method :nested?
      base.helper_method :beginning_of_chain
      base.helper_method :new_model
    end
    def render_field
      if params[:in_place_editing]
        render_field_for_inplace_editing
      else
        render_field_for_update_columns
      end
    end
    
    protected

    def nested?
      false
    end

    def render_field_for_inplace_editing
      register_constraints_with_action_columns(nested.constrained_fields, active_scaffold_config.update.hide_nested_column ? [] : [:update]) if nested?
      @record = find_if_allowed(params[:id], :update)
      render :inline => "<%= active_scaffold_input_for(active_scaffold_config.columns[params[:update_column].to_sym]) %>"
    end

    def render_field_for_update_columns
      @record = new_model
      column = active_scaffold_config.columns[params[:column]]
      unless column.nil?
        value = column_value_from_param_value(@record, column, params[:value])
        @record.send "#{column.name}=", value
        after_render_field(@record, column)
        source_id = params.delete(:source_id)
        render :partial => "render_field", :collection => Array(params[:update_columns]), :content_type => 'text/javascript', :locals => {:source_id => source_id}
      end
    end
    
    # override this method if you want to do something after render_field
    def after_render_field(record, column); end

    def authorized_for?(options = {})
      active_scaffold_config.model.authorized_for?(options)
    end

    def clear_flashes
      if request.xhr?
        flash.keys.each do |flash_key|
          flash[flash_key] = nil
        end
      end
    end

    def default_formats
      [:html, :js, :json, :xml, :yaml]
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
      if successful?
        action_name == 'create' ? 201 : 200
      else
        422
      end
    end

    # API response object that will be converted to XML/YAML/JSON using to_xxx
    def response_object
      @response_object = successful? ? (@record || @records) : @record.errors
    end

    # Success is the existence of certain variables and the absence of errors (when applicable).
    # Success can also be defined.
    def successful?
      if @successful.nil?
        @records or (@record and @record.errors.count == 0 and @record.no_errors_in_associated?)
      else
        @successful
      end
    end

    def successful=(val)
      @successful = (val) ? true : false
    end

    # Redirect to the main page (override if the ActiveScaffold is used as a component on another controllers page) for Javascript degradation
    def return_to_main
      redirect_to main_path_to_return
    end

    # Override this method on your controller to define conditions to be used when querying a recordset (e.g. for List). The return of this method should be any format compatible with the :conditions clause of ActiveRecord::Base's find.
    def conditions_for_collection
    end
  
    # Override this method on your controller to define joins to be used when querying a recordset (e.g. for List).  The return of this method should be any format compatible with the :joins clause of ActiveRecord::Base's find.
    def joins_for_collection
    end
  
    # Override this method on your controller to provide custom finder options to the find() call. The return of this method should be a hash.
    def custom_finder_options
      {}
    end
  
    #Overide this method on your controller to provide model with named scopes
    def beginning_of_chain
      active_scaffold_config.model
    end
        
    # Builds search conditions by search params for column names. This allows urls like "contacts/list?company_id=5".
    def conditions_from_params
      conditions = nil
      params.reject {|key, value| [:controller, :action, :id, :page, :sort, :sort_direction].include?(key.to_sym)}.each do |key, value|
        next unless active_scaffold_config.model.column_names.include?(key)
        if value.is_a?(Array)
          conditions = merge_conditions(conditions, ["#{active_scaffold_config.model.table_name}.#{key.to_s} in (?)", value])
        else
          conditions = merge_conditions(conditions, ["#{active_scaffold_config.model.table_name}.#{key.to_s} = ?", value])
        end
      end
      conditions
    end

    def new_model
      model = beginning_of_chain
      if model.columns_hash[model.inheritance_column]
        build_options = {model.inheritance_column.to_sym => active_scaffold_config.model_id} if nested? && nested.association && nested.association.collection?
        params = self.params # in new action inheritance_column must be in params
        params = params[:record] || {} unless params[model.inheritance_column] # in create action must be inside record key
        model = params.delete(model.inheritance_column).camelize.constantize if params[model.inheritance_column]
      end
      model.respond_to?(:build) ? model.build(build_options || {}) : model.new
    end

    private
    def respond_to_action(action)
      respond_to do |type|
        action_formats.each do |format|
          type.send(format){ send("#{action}_respond_to_#{format}") }
        end
      end
    end

    def action_formats
      @action_formats ||= if respond_to? "#{action_name}_formats"
        send("#{action_name}_formats")
      else
        (default_formats + active_scaffold_config.formats).uniq
      end
    end

    def response_code_for_rescue(exception)
      case exception
        when ActiveScaffold::RecordNotAllowed
          "403 Record Not Allowed"
        when ActiveScaffold::ActionNotAllowed
          "403 Action Not Allowed"
        else
          super
      end
    end
  end
end
