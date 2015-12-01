module ActiveScaffold::Actions
  module Core
    def self.included(base)
      base.class_eval do
        before_filter :handle_user_settings
        before_filter :check_input_device
        before_filter :register_constraints_with_action_columns, :unless => :nested?
        after_filter :clear_flashes
        after_filter :clear_storage
        rescue_from ActiveScaffold::RecordNotAllowed, ActiveScaffold::ActionNotAllowed, :with => :deny_access
      end
      base.helper_method :successful?
      base.helper_method :nested?
      base.helper_method :embedded?
      base.helper_method :loading_embedded?
      base.helper_method :calculate_query
      base.helper_method :new_model
      base.helper_method :touch_device?
      base.helper_method :hover_via_click?
    end
    def render_field
      if request.get?
        render_field_for_inplace_editing
        respond_to do |format|
          format.js { render :action => 'render_field_inplace', :layout => false }
        end
      else
        render_field_for_update_columns
        respond_to { |format| format.js }
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
    end

    def render_field_for_update_columns
      return if (@column = active_scaffold_config.columns[params.delete(:column)]).nil?
      @source_id = params.delete(:source_id)
      @columns = @column.update_columns || []
      @scope = params.delete(:scope)
      action = :subform if @scope
      action ||= params[:id] ? :update : :create
      @main_columns = active_scaffold_config.send(action).columns
      @columns << @column.name if @column.options[:refresh_link] && @columns.exclude?(@column.name)

      @record =
        if @column.send_form_on_update_column
          updated_record_with_form(@main_columns, params[:record], @scope)
        else
          updated_record_with_column(@column, params.delete(:value), @scope)
        end
      set_parent(@record) if params[:parent_controller] && @scope
      after_render_field(@record, @column)
    end

    def updated_record_with_form(columns, attributes, scope)
      if attributes && scope
        attributes = scope.gsub('[', '').split(']').inject(attributes) { |h, idx| h[idx] }
        id = attributes[:id]
      else
        id = params[:id]
      end

      # check permissions and support overriding to_param
      saved_record = find_if_allowed(id, :read) if id
      # call update_record_from_params with new_model
      # in other case some associations can be saved
      record = new_model
      copy_attributes(saved_record, record) if saved_record
      apply_constraints_to_record(record) unless scope
      update_record_from_params(record, columns, attributes || {}, true)
    end

    def updated_record_with_column(column, value, scope)
      record = params[:id] ? find_if_allowed(params[:id], :read).dup : new_model
      apply_constraints_to_record(record) unless scope || params[:id]
      value = column_value_from_param_value(record, column, value)
      record.send "#{column.name}=", value
      record.id = params[:id]
      record
    end

    def set_parent(record)
      controller = "#{params[:parent_controller].camelize}Controller".constantize
      parent_model = controller.active_scaffold_config.model
      child_association = params[:child_association].presence || @scope.split(']').first.sub(/^\[/, '')
      association = parent_model.reflect_on_association(child_association.to_sym).try(:reverse)
      return if association.nil?

      parent = parent_model.new
      copy_attributes(parent_model.find(params[:parent_id]), parent) if params[:parent_id]
      parent.id = params[:parent_id]
      parent = update_record_from_params(parent, active_scaffold_config_for(parent_model).send(params[:parent_id] ? :update : :create).columns, params[:record], true) if @column.send_form_on_update_column
      apply_constraints_to_record(parent) unless params[:parent_id]
      if record.class.reflect_on_association(association).collection?
        record.send(association) << parent
      else
        record.send("#{association}=", parent)
      end
    end

    def copy_attributes(orig, dst = nil)
      dst ||= orig.class.new
      attributes = orig.attributes
      if orig.class.respond_to?(:accessible_attributes) && orig.class.accessible_attributes.present?
        attributes.each { |attr, value| dst.send :write_attribute, attr, value if orig.class.accessible_attributes.deny? attr }
        attributes = attributes.slice(*orig.class.accessible_attributes)
      elsif orig.class.respond_to? :protected_attributes
        orig.class.protected_attributes.each { |attr| dst.send :write_attribute, attr, orig[attr] if attr.present? }
        attributes = attributes.except(*orig.class.protected_attributes)
      end
      dst.attributes = attributes
      dst
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
      active_scaffold_config.model.as_marked.each(&block)
    end

    def marked_records
      active_scaffold_session_storage['marked_records'] ||= {}
    end

    def default_formats
      [:html, :js, :json, :xml]
    end

    # Returns true if the client accepts one of the MIME types passed to it
    # ex: accepts? :html, :xml
    def accepts?(*types)
      request.accepts.compact.each do |priority|
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

    # API response object that will be converted to XML/JSON using to_xxx
    def response_object
      @response_object ||= successful? ? (@record || @records) : @record.errors
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

    # Overide this method on your controller to provide model with named scopes
    def beginning_of_chain
      active_scaffold_config.model
    end

    # Builds search conditions by search params for column names. This allows urls like "contacts/list?company_id=5".
    def conditions_from_params
      @conditions_from_params ||= begin
        conditions = {}
        params.except(:controller, :action, :page, :sort, :sort_direction, :format, :id).each do |key, value|
          column = active_scaffold_config.model.columns_hash[key.to_s]
          next unless column
          key = key.to_sym
          not_string = [:string, :text].exclude?(column.type)
          next if active_scaffold_constraints[key]
          next if nested? && nested.param_name == key
          conditions[key] =
            if value.is_a?(Array)
              value.map { |v| v == '' && not_string ? nil : ActiveScaffold::Core.column_type_cast(v, column) }
            else
              value == '' && not_string ? nil : ActiveScaffold::Core.column_type_cast(value, column)
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

    def get_row(crud_type_or_security_options = :read)
      klass = beginning_of_chain.preload(active_scaffold_preload)
      @record = find_if_allowed(params[:id], crud_type_or_security_options, klass)
    end

    def active_scaffold_session_storage_key(id = nil)
      id ||= params[:eid] || "#{params[:controller]}#{"_#{nested_parent_id}" if nested?}"
      "as:#{id}"
    end

    def active_scaffold_session_storage(id = nil)
      session_index = active_scaffold_session_storage_key(id)
      session[session_index] ||= {}
      session[session_index]
    end

    def clear_storage
      session_index = active_scaffold_session_storage_key
      session.delete(session_index) unless session[session_index].present?
    end

    # at some point we need to pass the session and params into config. we'll just take care of that before any particular action occurs by passing those hashes off to the UserSettings class of each action.
    def handle_user_settings
      storage = active_scaffold_config.store_user_settings ? active_scaffold_session_storage : {}
      active_scaffold_config.actions.each do |action_name|
        conf_instance = active_scaffold_config.send(action_name) rescue next
        next if conf_instance.class::UserSettings == ActiveScaffold::Config::Base::UserSettings # if it hasn't been extended, skip it
        conf_instance.user = conf_instance.class::UserSettings.new(conf_instance, storage, params)
      end
    end

    def check_input_device
      if request.env['HTTP_USER_AGENT'] && request.env['HTTP_USER_AGENT'][/(iPhone|iPod|iPad)/i]
        session[:input_device_type] = 'TOUCH'
        session[:hover_supported] = false
      else
        session[:input_device_type] = 'MOUSE'
        session[:hover_supported] = true
      end if session[:input_device_type].nil?
    end

    def touch_device?
      session[:input_device_type] == 'TOUCH'
    end

    def hover_via_click?
      session[:hover_supported] == false
    end

    # call this method in your action_link action to simplify processing of actions
    # eg for member action_link :fire
    # process_action_link_action do |record|
    #   record.update_attributes(:fired => true)
    #   self.successful = true
    #   flash[:info] = 'Player fired'
    # end
    def process_action_link_action(render_action = :action_update, crud_type_or_security_options = nil)
      if request.get?
        # someone has disabled javascript, we have to show confirmation form first
        @record = find_if_allowed(params[:id], :read) if params[:id]
        respond_to_action(:action_confirmation)
      else
        @action_link = active_scaffold_config.action_links[action_name]
        if params[:id]
          crud_type_or_security_options ||= {:crud_type => (request.post? || request.put?) ? :update : :delete, :action => action_name}
          get_row(crud_type_or_security_options)
          if @record.nil?
            self.successful = false
            flash[:error] = as_(:no_authorization_for_action, :action => action_name)
          else
            yield @record
          end
        else
          yield
        end
        respond_to_action(render_action)
      end
    end

    def action_confirmation_respond_to_html(confirm_action = action_name.to_sym)
      link = active_scaffold_config.action_links[confirm_action]
      render :action => 'action_confirmation', :locals => {:record => @record, :link => link}
    end

    def action_update_respond_to_html
      redirect_to :action => 'index'
    end

    def action_update_respond_to_js
      render(:action => 'on_action_update')
    end

    def action_update_respond_to_xml
      render :xml => successful? ? '' : response_object, :only => list_columns_names + [active_scaffold_config.model.primary_key], :include => association_columns(list_columns_names), :methods => virtual_columns(list_columns_names), :status => response_status
    end

    def action_update_respond_to_json
      render :json => successful? ? '' : response_object, :only => list_columns_names + [active_scaffold_config.model.primary_key], :include => association_columns(list_columns_names), :methods => virtual_columns(list_columns_names), :status => response_status
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
      columns.reject { |col| active_scaffold_config.model.columns_hash[col.to_s] || active_scaffold_config.model.reflect_on_association(col) }
    end

    def association_columns(columns)
      columns.select { |col| active_scaffold_config.model.reflect_on_association(col) }
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
      @action_formats ||=
        if respond_to? "#{action_name}_formats", true
          send("#{action_name}_formats")
        else
          (default_formats + active_scaffold_config.formats).uniq
        end
    end
  end
end
