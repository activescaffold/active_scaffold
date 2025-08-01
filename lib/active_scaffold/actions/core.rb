module ActiveScaffold::Actions
  module Core
    def self.included(base)
      base.class_eval do
        before_action :set_vary_accept_header
        before_action :check_input_device
        before_action :register_constraints_with_action_columns, unless: :nested?
        after_action :clear_flashes
        after_action :dl_cookie
        around_action :clear_storage
        rescue_from ActiveScaffold::RecordNotAllowed, ActiveScaffold::ActionNotAllowed, with: :deny_access
      end
      base.helper_method :active_scaffold_config
      base.helper_method :successful?
      base.helper_method :nested?
      base.helper_method :grouped_search?
      base.helper_method :embedded?
      base.helper_method :loading_embedded?
      base.helper_method :calculate_query
      base.helper_method :calculate_subquery
      base.helper_method :new_model
      base.helper_method :touch_device?
      base.helper_method :hover_via_click?
    end

    def render_field
      if request.get? || request.head?
        render_field_for_inplace_editing
        respond_to do |format|
          format.js { render action: 'render_field_inplace', layout: false }
        end
      elsif params[:tabbed_by]
        add_tab
        respond_to do |format|
          format.js { render action: 'add_tab', layout: false }
        end
      else
        render_field_for_update_columns
        respond_to { |format| format.js }
      end
    end

    protected

    def loading_embedded?
      @loading_embedded ||= active_scaffold_embedded_params.delete(:loading)
    end

    def embedded?
      params[:eid]
    end

    def nested?
      false
    end

    def grouped_search?
      false
    end

    def render_field_for_inplace_editing
      @column = active_scaffold_config.columns[params[:update_column]]
      @record = find_if_allowed(params[:id], crud_type: :update, column: params[:update_column])
    end

    def add_tab
      process_render_field_params
      @column = @main_columns.find_by_name(params[:column])
      @record = updated_record_with_form(@main_columns, {}, @scope)
    end

    def process_render_field_params
      @source_id = params.delete(:source_id)
      @scope = params.delete(:scope)
      if @scope
        @form_action = :subform
      elsif active_scaffold_config.actions.include? params[:form_action]&.to_sym
        @form_action = params.delete(:form_action).to_sym
      end
      @form_action ||= params[:id] ? :update : :create
      @main_columns = active_scaffold_config.send(@form_action).columns
    end

    def render_field_for_update_columns
      return if (@column = active_scaffold_config.columns[params.delete(:column)]).nil?

      @columns = @column.update_columns || []
      @columns += [@column.name] if @column.options[:refresh_link] && @columns.exclude?(@column.name)
      process_render_field_params

      @record = find_from_scope(setup_parent, @scope) if main_form_controller && @scope
      if @column.send_form_on_update_column
        @record ||= updated_record_with_form(@main_columns, params[:record] || params[:search], @scope)
      elsif @record
        update_column_from_params(@record, @column, params.delete(:value), true)
      else
        @record = updated_record_with_column(@column, params.delete(:value), @scope)
      end
      after_render_field(@record, @column)
    end

    def updated_record_with_form(columns, attributes, scope)
      if attributes && scope
        attributes = scope.delete('[').split(']').inject(attributes) { |h, idx| h[idx] }
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
      create_association_with_parent record, check_match: true if nested?
      if @form_action == :field_search
        update_columns_from_params(record, columns, attributes || {}, :read, avoid_changes: true, search_attributes: true)
      else
        update_record_from_params(record, columns, attributes || {}, true)
      end
    end

    def updated_record_with_column(column, value, scope)
      record = params[:id] ? copy_attributes(find_if_allowed(params[:id], :read)) : new_model
      apply_constraints_to_record(record) unless scope || params[:id]
      create_association_with_parent record, check_match: true if nested?
      if @form_action == :field_search && value.is_a?(Array) && column.association&.singular?
        # don't assign value if it's an array and column is singular association,
        # e.g. value came from multi-select on search form
        # use instance variable so it's available in the view and helpers
        @value = value
      else
        update_column_from_params(record, column, value, true)
      end
      record.id = params[:id]
      record
    end

    def subform_child_association
      params[:child_association].presence || (@scope.split(']').first.sub(/^\[/, '').presence if @scope)
    end

    def parent_controller_name
      "#{params[:parent_controller].camelize}Controller"
    end

    def setup_parent
      cfg = main_form_controller.active_scaffold_config
      parent_model = cfg.model
      parent = parent_model.new
      copy_attributes(find_if_allowed(params[:parent_id], :read, parent_model), parent) if params[:parent_id]
      parent.id = params[:parent_id]
      apply_constraints_to_record(parent) unless params[:parent_id]
      if @column.send_form_on_update_column
        parent = update_record_from_params(parent, cfg.send(params[:parent_id] ? :update : :create).columns, params[:record], true)
      end

      if params[:nested] # form in nested scaffold, set nested parent_record to parent
        nested = ActiveScaffold::DataStructures::NestedInfo.get(parent.class, params[:nested])
        if nested&.child_association && !nested.child_association.polymorphic?
          apply_constraints_to_record(parent, constraints: {nested.child_association.name => nested.parent_id})
        end
      end
      parent
    end

    def find_from_scope(parent, scope)
      parts = scope[1..-2].split('][')
      record = parent

      while parts.present?
        part = parts.shift
        return unless record.respond_to?(part)

        association = record.class.reflect_on_association(part)
        id = parts.shift.to_i if association&.collection?
        record = record.send(part)
        if id
          record = record.find { |child| child.id == id }
          record ||= @new_records&.dig(association.klass, id.to_s)
        end
        return if record.nil?
      end

      record
    end

    def copy_attributes(orig, dst = nil)
      dst ||= orig.class.new
      orig.attributes.each { |attr, value| dst.send :write_attribute, attr, value }
      dst
    end

    def parent_sti_controller
      return unless params[:parent_sti]

      unless defined? @parent_sti_controller
        controller = look_for_parent_sti_controller
        @parent_sti_controller = controller.controller_path == params[:parent_sti] ? controller : false
      end
      @parent_sti_controller
    end

    # override this method if you want to do something after render_field
    def after_render_field(record, column); end

    def authorized_for?(options = {})
      active_scaffold_config.model.authorized_for?(options)
    end

    def clear_flashes
      flash.clear if request.xhr?
    end

    def dl_cookie
      cookies[params[:_dl_cookie]] = {value: Time.now.to_i, expires: 1.day.since} if params[:_dl_cookie]
    end

    def each_marked_record(&)
      active_scaffold_config.model.as_marked.each(&)
    end

    def marked_records
      active_scaffold_session_storage['marked_records'] ||= {}
    end

    def default_formats
      %i[html js json xml]
    end

    # Returns true if the client accepts one of the MIME types passed to it
    # ex: accepts? :html, :xml
    def accepts?(*types)
      request.accepts.compact.each do |priority|
        # Because IE always sends */* in the accepts header and we assume
        # that if you really wanted XML or something else you would say so
        # explicitly, we will assume */* to only ask for :html
        return types.include?(:html) if priority == Mime::ALL

        return true if types.include?(priority.to_sym)
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

    def response_to_api(format, columns_names, options = {})
      render(
        options.reverse_merge(
          format => response_object,
          only: columns_names + [active_scaffold_config.model.primary_key],
          include: association_columns(columns_names),
          methods: virtual_columns(columns_names),
          status: response_status
        )
      )
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
      @successful = val ? true : false
    end

    # Redirect to the main page (override if the ActiveScaffold is used as a component on another controllers page) for Javascript degradation
    def return_to_main
      options = main_path_to_return
      # use url_for in case main_path_to_return returns Hash with status param,
      # which would be interpreted as status option to redirect_to instead of url param
      redirect_to options.is_a?(Hash) ? url_for(options) : options
    end

    def filtered_query
      beginning_of_chain
    end

    # Overide this method on your controller to provide model with named scopes
    def beginning_of_chain
      active_scaffold_config.model
    end

    # Builds search conditions by search params for column names. This allows urls like "contacts/list?company_id=5".
    def conditions_from_params
      @conditions_from_params ||= begin
        conditions = [{}]
        supporting_range = %i[date datetime integer decimal float bigint]
        params.except(:controller, :action, :page, :sort, :sort_direction, :format, :id).each do |key, value|
          distinct = true if key.match?(/!$/)
          column = active_scaffold_config._columns_hash[key.to_s[0..(distinct ? -2 : -1)]]
          next unless column

          key = column.name.to_sym
          not_string = %i[string text].exclude?(column.type)
          next if active_scaffold_constraints[key]
          next if nested? && nested.param_name == key

          range = supporting_range.include?(column.type) && value.is_a?(String) && value.scan('..').size == 1
          value = value.split('..') if range
          value =
            if value.is_a?(Array)
              value.map { |v| v == '' && not_string ? nil : ActiveScaffold::Core.column_type_cast(v, column) }
            elsif value == '' && (not_string || column.null)
              ActiveScaffold::Core.column_type_cast(column.default, column)
            else
              ActiveScaffold::Core.column_type_cast(value, column)
            end
          value = Range.new(*value) if range
          if distinct
            conditions << active_scaffold_config.model.arel_table[key].not_eq(value)
          else
            conditions[0][key] = value
          end
        end
        conditions
      end
    end

    def empty_model
      relation = beginning_of_chain
      if nested? && nested.plural_association? && nested.match_model?(active_scaffold_config.model)
        build_options = sti_nested_build_options(relation.klass)
      end
      relation.respond_to?(:build) ? relation.build(build_options || {}) : relation.new
    end

    def new_model
      empty_model.tap do |record|
        assign_default_attributes record
      end
    end

    def assign_default_attributes(record)
      active_scaffold_config.columns.each do |column|
        record.write_attribute column.name, column.default_value if column.default_value?
      end
    end

    def sti_nested_build_options(klass)
      config = active_scaffold_config_for(klass)
      return unless config

      column = klass.inheritance_column
      return unless column && config._columns_hash[column]

      model_name = params.delete(column) # in new action inheritance_column must be in params
      model_name ||= params[:record]&.delete(column) # in create action must be inside record key
      model_name = model_name.camelize if model_name
      model_name ||= active_scaffold_config.model.name
      {column.to_sym => model_name} if model_name
    end

    def get_row(crud_type_or_security_options = :read)
      klass = filtered_query
      klass = klass.preload(active_scaffold_preload) unless active_scaffold_config.mongoid?
      @record = find_if_allowed(params[:id], crud_type_or_security_options, klass)
    end

    def active_scaffold_embedded_params
      params[:embedded] || {}
    end

    def clear_storage
      yield if block_given?
    ensure
      session_index = active_scaffold_session_storage_key
      session.delete(session_index) if session[session_index].blank?
    end

    def set_vary_accept_header
      response.set_header 'vary', 'Accept'
    end

    def check_input_device
      return unless session[:input_device_type].nil?
      return if request.env['HTTP_USER_AGENT'].nil?

      if request.env['HTTP_USER_AGENT'].match?(/(iPhone|iPod|iPad)/i)
        session[:input_device_type] = 'TOUCH'
        session[:hover_supported] = false
      else
        session[:input_device_type] = 'MOUSE'
        session[:hover_supported] = true
      end
    end

    def touch_device?
      session[:input_device_type] == 'TOUCH'
    end

    def hover_via_click?
      session[:hover_supported] == false
    end

    def params_hash?(value)
      value.is_a?(Hash) || controller_params?(value)
    end

    def controller_params?(value)
      value.is_a?(::ActionController::Parameters)
    end

    def params_hash(value)
      if controller_params?(value)
        value.to_unsafe_h.with_indifferent_access
      else
        value
      end
    end

    # call this method in your action_link action to simplify processing of actions
    # eg for member action_link :fire
    # process_action_link_action do |record|
    #   record.update(fired: true)
    #   self.successful = true
    #   flash[:info] = 'Player fired'
    # end
    def process_action_link_action(render_action = :action_update, crud_type_or_security_options = nil)
      if request.get? || request.head?
        # someone has disabled javascript, we have to show confirmation form first
        @record = find_if_allowed(params[:id], :read) if params[:id]
        respond_to_action(:action_confirmation)
      else
        @action_link = active_scaffold_config.action_links[action_name]
        if params[:id]
          crud_type_or_security_options ||= {crud_type: request.delete? ? :delete : :update, action: action_name}
          get_row(crud_type_or_security_options)
          if @record.nil?
            self.successful = false
            flash[:error] = as_(:no_authorization_for_action, action: @action_link&.label(nil) || action_name)
          else
            yield @record
          end
        else
          raise ActiveScaffold::ActionNotAllowed unless action_link_authorized? @action_link

          yield
        end
        respond_to_action(render_action)
      end
    end

    def action_link_authorized?(link)
      link&.security_method.nil? || !respond_to?(link.security_method, true) || Array(send(link.security_method))[0]
    end

    def action_confirmation_respond_to_html(confirm_action = action_name.to_sym)
      link = active_scaffold_config.action_links[confirm_action]
      render action: 'action_confirmation', locals: {record: @record, link: link}
    end

    def action_update_respond_on_iframe
      responds_to_parent { action_update_respond_to_js }
    end

    def action_update_respond_to_html
      redirect_to action: 'index'
    end

    def action_update_respond_to_js
      render action: 'on_action_update', formats: [:js], layout: false
    end

    def action_update_respond_to_xml
      response_to_api(:xml, list_columns_names)
    end

    def action_update_respond_to_json
      response_to_api(:json, list_columns_names)
    end

    def objects_for_etag
      @last_modified ||= @record.updated_at
      [@record, ('xhr' if request.xhr?)]
    end

    def view_stale?
      objects = objects_for_etag
      if objects.is_a?(Array)
        args = {etag: objects.to_a}
        args[:last_modified] = @last_modified if @last_modified
      elsif objects.is_a?(Hash)
        args = {last_modified: @last_modified}.merge(objects)
      else
        args = objects
      end
      stale?(args)
    end

    def conditional_get_support?
      request.get? && active_scaffold_config.conditional_get_support
    end

    def virtual_columns(columns)
      columns.reject do |col|
        active_scaffold_config._columns_hash[col.to_s] || active_scaffold_config.columns[col]&.association
      end
    end

    def association_columns(columns)
      columns.select { |col| active_scaffold_config.columns[col]&.association }
    end

    private

    def respond_to_action(action)
      return unless !conditional_get_support? || view_stale?

      respond_to do |type|
        action_formats.each do |format|
          type.send(format) do
            method_name = respond_method_for(action, format)
            send(method_name) if method_name
          end
        end
      end
    end

    def respond_method_for(action, format)
      if format == :html && params[:iframe] == 'true'
        method_name = "#{action}_respond_on_iframe"
        return method_name if respond_to?(method_name, true)
      end
      method_name = "#{action}_respond_to_#{format}"
      method_name if respond_to?(method_name, true)
    end

    def action_formats
      @action_formats ||=
        if respond_to? :"#{action_name}_formats", true
          send(:"#{action_name}_formats")
        else
          (default_formats + active_scaffold_config.formats).uniq
        end
    end

    def look_for_parent_sti_controller
      klass = self.class.active_scaffold_config.model
      loop do
        klass = klass.superclass
        controller = self.class.active_scaffold_controller_for(klass)
        cfg = controller.active_scaffold_config if controller.uses_active_scaffold?
        next unless cfg&.add_sti_create_links?
        return controller if cfg.sti_children.map(&:to_s).include? self.class.active_scaffold_config.model.name.underscore
      end
    rescue ActiveScaffold::ControllerNotFound => e
      logger.warn "#{e.message} looking for parent_sti of #{self.class.active_scaffold_config.model.name}"
      nil
    end
  end
end
