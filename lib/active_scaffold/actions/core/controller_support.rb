# frozen_string_literal: true

module ActiveScaffold::Actions
  module Core
    module ControllerSupport
      protected

      def authorized_for?(options = {})
        active_scaffold_config.model.authorized_for?(options)
      end

      def clear_flashes
        flash.clear if request.xhr?
      end

      def dl_cookie
        cookies[params[:_dl_cookie]] = {value: Time.now.to_i, expires: 1.day.since} if params[:_dl_cookie]
      end

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

      def get_row(crud_type_or_security_options = :read)
        get_record(crud_type_or_security_options)
      end

      def get_record(crud_type_or_security_options = :read)
        klass = filtered_query
        klass = klass.preload(active_scaffold_preload) unless active_scaffold_config.mongoid?
        @record = find_if_allowed(params[:id], crud_type_or_security_options, klass)
      end

      def active_scaffold_embedded_params
        @active_scaffold_embedded_params ||= begin
          embedded = params[:embedded]
          if embedded.nil?
            {}
          else
            raise ActionController::BadRequest, 'Invalid embedded parameters' unless embedded.is_a?(ActionController::Parameters)

            payload = ActiveScaffold::ParameterSigning.embedded_payload(embedded, controller: controller_path)
            unless ActiveScaffold::ParameterSigning.valid_signature?(payload, params[:eid], purpose: :embedded)
              raise ActionController::BadRequest, 'Invalid embedded signature'
            end

            embedded
          end
        end
      end

      def clear_storage
        yield if block_given?
      ensure
        session_index = active_scaffold_session_storage_key
        session.delete(session_index) if session[session_index].blank?
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

      def parent_controller_name
        "#{params[:parent_controller].camelize}Controller"
      end

      def parent_sti_controller
        return unless params[:parent_sti]

        unless defined? @parent_sti_controller
          controller = look_for_parent_sti_controller
          @parent_sti_controller = controller.controller_path == params[:parent_sti] ? controller : false
        end
        @parent_sti_controller
      end

      def preload_for_form(columns, preloaded_models = [])
        association_columns = []
        columns.each_column(flatten: true, skip_authorization: true) do |column|
          association_columns << column if column.association && column.subform_includes
        end

        association_columns.filter_map do |column|
          if column.form_ui.nil? && column.subform_includes == true &&
             preloaded_models.exclude?(column.association.klass)
            config = active_scaffold_config_for(column.association.klass)
            if config.actions.include?(:subform)
              preload_values = preload_for_form(config.subform.columns, preloaded_models + [column.association.klass])
            end
            preload_values ? {column.name => preload_values} : column.name
          elsif column.subform_includes != true
            {column.name => column.subform_includes}
          else
            column.name
          end
        end
      end
    end
  end
end
