module ActiveScaffold::Actions
  module Core
    def self.included(base)
      base.class_eval do
        before_filter :register_constraints_with_action_columns, :unless => :nested?
        after_filter :clear_flashes
        after_filter :clear_storage
        rescue_from ActiveScaffold::RecordNotAllowed, ActiveScaffold::ActionNotAllowed, :with => :deny_access
      end
      base.helper_method :successful?
      base.helper_method :nested?
      base.helper_method :calculate_query
      base.helper_method :new_model
    end
    def render_field
      if request.get?
        render_field_for_inplace_editing
      else
        render_field_for_update_columns
      end
    end
    
    protected
    def loading_embedded?
      @loading_embedded ||= params.delete(:embedded)
    end

    def embedded?
      params[:eid]
    end

    def nested?
      false
    end

    def render_field_for_inplace_editing
      @column = active_scaffold_config.columns[params[:update_column]]
      @record = find_if_allowed(params[:id], :crud_type => :update, :column => params[:update_column])
      render :action => 'render_field_inplace', :layout => false
    end

    def render_field_for_update_columns
      @column = active_scaffold_config.columns[params.delete(:column)]
      unless @column.nil?
        @source_id = params.delete(:source_id)
        @columns = @column.update_columns || []
        @scope = params.delete(:scope)
        @main_columns = active_scaffold_config.send(@scope ? :subform : (params[:id] ? :update : :create)).columns
        @columns << @column.name if @column.options[:refresh_link] && @columns.exclude?(@column.name)
        
        if @column.send_form_on_update_column
          if @scope
            hash = @scope.gsub('[','').split(']').inject(params[:record]) do |hash, index|
              hash[index]
            end
            id = hash[:id]
          else
            hash = params[:record]
            id = params[:id]
          end

          # check permissions and support overriding to_param
          record = find_if_allowed(id, :update) if id
          # call update_record_from_params with new_model
          # in other case some associations can be saved
          @record = new_model
          @record.attributes = record.attributes if record
          @record.id = id
          apply_constraints_to_record(@record) unless @scope
          @record = update_record_from_params(@record, @main_columns, hash, true)
        else
          @record = params[:id] ? find_if_allowed(params[:id], :update) : new_model
          if @record.new_record?
            apply_constraints_to_record(@record) unless @scope
          else
            @record = @record.dup
          end
          value = column_value_from_param_value(@record, @column, params.delete(:value))
          @record.send "#{@column.name}=", value
          @record.id = params[:id]
        end
        set_parent(@record) if @record.id.nil? && params[:parent_controller] && params[:child_association]
        
        after_render_field(@record, @column)
      end
    end

    def set_parent(record)
      parent_model = params[:parent_controller].singularize.camelize.constantize
      association = parent_model.reflect_on_association(params[:child_association].to_sym).try(:reverse)
      if association
        parent = parent_model.new
        parent.attributes = parent_model.find(params[:parent_id]).attributes if params[:parent_id]
        parent.id = params[:parent_id]
        parent = update_record_from_params(parent, active_scaffold_config_for(parent_model).send(params[:parent_id] ? :update : :create).columns, params[:record]) if @column.send_form_on_update_column
        apply_constraints_to_record(parent) if params[:parent_id]
        if record.class.reflect_on_association(association).collection?
          record.send(association) << parent
        else
          record.send("#{association}=", parent)
        end
      end
    end
    
    # override this method if you want to do something after render_field
    def after_render_field(record, column); end

    def authorized_for?(options = {})
      active_scaffold_config.model.authorized_for?(options)
    end

    def clear_flashes
      flash.clear if request.xhr?
    end

    def each_marked_record(&block)
      active_scaffold_config.model.find(marked_records.to_a).each &block
    end

    def marked_records
      active_scaffold_session_storage[:marked_records] ||= Set.new
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

    # Success is the existence of one or more model objects. Most actions
    # circumvent this method by setting @success directly.
    def successful?
      if @successful.nil?
        true
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
  
    #Overide this method on your controller to provide model with named scopes
    def beginning_of_chain
      active_scaffold_config.model
    end
        
    # Builds search conditions by search params for column names. This allows urls like "contacts/list?company_id=5".
    def conditions_from_params
      @conditions_from_params ||= begin
        conditions = {}
        params.except(:controller, :action, :page, :sort, :sort_direction, :id).each do |key, value|
          column = active_scaffold_config.model.columns_hash[key.to_s]
          next unless column
          key = key.to_sym
          not_string = [:string, :text].exclude?(column.type)
          next if active_scaffold_constraints[key]
          next if nested? and nested.param_name == key
          conditions[key] = if value.is_a?(Array)
            value.map {|v| v == '' && not_string ? nil : column.type_cast(v) }
          else
            value == '' && not_string ? nil : column.type_cast(value)
          end
        end
        conditions
      end
    end

    def new_model
      model = beginning_of_chain
      if nested? && nested.association && nested.association.collection? && model.columns_hash[column = model.inheritance_column]
        model_name = params.delete(column) # in new action inheritance_column must be in params
        model_name ||= params[:record].delete(column) unless params[:record].blank? # in create action must be inside record key
        model_name = model_name.camelize if model_name
        model_name ||= active_scaffold_config.model.name
        build_options = {column.to_sym => model_name} if model_name
      end
      model.respond_to?(:build) ? model.build(build_options || {}) : model.new
    end

    def objects_for_etag
      @last_modified ||= @record.updated_at
      [@record, ('xhr' if request.xhr?)]
    end

    def view_stale?
      objects = objects_for_etag
      if objects.is_a?(Array)
        args = {:etag => objects.to_a}
        args[:last_modified] = @last_modified if @last_modified
      elsif objects.is_a?(Hash)
        args = {:last_modified => @last_modified}.merge(objects)
      else
        args = objects
      end
      stale?(args)
    end

    def conditional_get_support?
      request.get? && active_scaffold_config.conditional_get_support
    end

    def virtual_columns(columns)
      columns.reject {|col| active_scaffold_config.model.columns_hash[col] || active_scaffold_config.model.reflect_on_association(col)}
    end

    def association_columns(columns)
      columns.select {|col| active_scaffold_config.model.reflect_on_association(col)}
    end

    private
    def respond_to_action(action)
      return unless !conditional_get_support? || view_stale?
      respond_to do |type|
        action_formats.each do |format|
          type.send(format) do
            if respond_to?(method_name = "#{action}_respond_to_#{format}", true)
              send(method_name)
            end
          end
        end
      end
    end

    def action_formats
      @action_formats ||= if respond_to? "#{action_name}_formats", true
        send("#{action_name}_formats")
      else
        (default_formats + active_scaffold_config.formats).uniq
      end
    end
  end
end
