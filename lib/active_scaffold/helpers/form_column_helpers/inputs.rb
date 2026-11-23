# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      module Inputs
        # This method decides which input to use for the given column.
        # It does not do any rendering. It only decides which method is responsible for rendering.
        def active_scaffold_input_for(column, scope = nil, options = nil, form_columns: nil)
          options ||= active_scaffold_input_options(column, scope)
          options = update_columns_options(column, scope, options, form_columns: form_columns)
          active_scaffold_render_input(column, options)
        end

        def active_scaffold_render_input(column, options)
          record = options[:object]
          if (input_method = override_form_field(column))
            send(input_method, record, options)
          elsif (input_method = _as_configured_form_input_method(column))
            _as_render_configured_form_input(column, options, input_method)
          elsif column.association
            _as_render_association_form_input(column, options)
          elsif column.virtual?
            _as_render_virtual_form_input(column, record, options)
          elsif (input_method = override_input(column.column_type))
            send(input_method, column, options)
          else
            _as_render_default_form_input(column, record, options)
          end
        rescue StandardError => e
          handle_exception_on_column(e, column, record)
        end

        def _as_configured_form_input_method(column)
          override_input(column.form_ui) if column.form_ui
        end

        def _as_render_configured_form_input(column, options, method)
          send(method, column, options, ui_options: (column.form_ui_options || column.options).except(:collapsible))
        end

        def _as_render_association_form_input(column, options)
          raise ArgumentError, "Unknown form_ui `#{column.form_ui}' for column `#{column.name}'" if column.form_ui

          active_scaffold_input_select(column, options)
        end

        def _as_render_virtual_form_input(column, record, options)
          options[:value] = format_number_value(record.send(column.name), column.options) if column.number?
          active_scaffold_input_virtual(column, options)
        end

        def _as_render_default_form_input(column, record, options)
          options = active_scaffold_input_text_options(options) if column.text? || column.number?
          if column.column_type == :string && options[:maxlength].blank?
            options[:maxlength] = column.type_for_attribute.limit
            options[:size] ||= options[:maxlength].to_i > 30 ? 30 : options[:maxlength]
          end
          options[:value] = format_number_value(record.send(column.name), column.options) if column.number?
          text_field(:record, column.name, options.merge(column.options).except(:format))
        end
        private :_as_configured_form_input_method, :_as_render_configured_form_input,
                :_as_render_association_form_input, :_as_render_virtual_form_input, :_as_render_default_form_input

        # the standard active scaffold options used for textual inputs
        def active_scaffold_input_text_options(options = {})
          options[:autocomplete] ||= 'off'
          options[:class] = "#{options[:class]} text-input".strip
          options
        end

        def action_for_validation(record)
          record&.persisted? ? :update : :create
        end

        # the standard active scaffold options used for class, name and scope
        def active_scaffold_input_options(column, scope = nil, options = {})
          name = scope ? "record#{scope}[#{column.name}]" : "record[#{column.name}]"
          record = options[:object]
          options[:required] = true if _as_required_form_input?(column, record, scope)
          options[:placeholder] = column.placeholder if column.placeholder.present?
          id_control = _as_form_input_id(column, scope)
          classes = "#{column.name}-input#{' numeric-input' if column.number?}"
          collapsible_id = "container_#{id_control}" if (column.form_ui_options || column.options)[:collapsible]

          attributes = {name: name, class: classes, id: id_control, collapsible_id: collapsible_id}.merge(options)
          context = {column: column, form_ui: column.form_ui}
          as_element_attributes(:form_control, proc_options: context, **attributes)
        end

        def _as_required_form_input?(column, record, scope)
          column.required?(action_for_validation(record)) &&
            (!@disable_required_for_new || scope.nil? || record&.persisted?)
        end

        def _as_form_input_id(column, scope)
          id = "record_#{column.name}_#{[params[:eid], params[:parent_id] || params[:id]].compact.join '_'}"
          id += scope_id(scope) if scope
          id
        end
        private :_as_required_form_input?, :_as_form_input_id

        def current_form_columns(record, scope, subform_controller = nil)
          if @main_columns && (scope.nil? || subform_controller == controller.class)
            @main_columns.visible_columns_names
          elsif scope
            subform_controller.active_scaffold_config.subform.columns.visible_columns_names
          elsif %i[new create edit update render_field].include? action_name.to_sym
            # disable update_columns for inplace_edit (GET render_field)
            return if action_name == 'render_field' && request.get?

            active_scaffold_config.send(record.new_record? ? :create : :update).columns.visible_columns_names
          end
        end

        def url_options_for_render_field(column, record, scope, subform_controller, url_params)
          url_params.reverse_merge! params_for(action: 'render_field', column: column.name, id: record.to_param)
          if nested? && scope
            url_params[:nested] = url_params.slice(:parent_scaffold, :association, nested.param_name)
            url_params = url_params.except(:parent_scaffold, :association, nested.param_name)
          end
          if scope
            url_params[:parent_controller] ||= url_params[:controller].gsub(%r{^/}, '')
            url_params[:controller] = subform_controller.controller_path
            url_params[:scope] = scope
            url_params[:parent_id] = params[:parent_id] || params[:id]
          end
          url_params
        end

        def update_columns_options(column, scope, options, force: false, form_columns: nil, url_params: {})
          record = options[:object]
          subform_controller = controller.class.active_scaffold_controller_for(record.class) if scope
          form_columns ||= current_form_columns(record, scope, subform_controller)
          update_columns = column.update_columns&.flat_map { |col| col.is_a?(Hash) ? col.keys : col }
          force = true if update_columns&.include?(:__root__)

          return options unless force || _as_render_updated_columns?(form_columns, update_columns)

          url_params = url_options_for_render_field(column, record, scope, subform_controller, url_params)
          _as_add_update_columns_options(options, column, url_params)
          options
        end

        def _as_add_update_columns_options(options, column, url_params)
          options[:class] = "#{options[:class]} update_form".strip
          options['data-update_url'] = url_for(signed_url_options(url_params))
          options['data-update_send_form'] = column.update_columns&.any?(Hash) || column.send_form_on_update_column
          if column.options[:send_form_selector]
            options['data-update_send_form_selector'] = column.options[:send_form_selector]
          end
          options['data-skip-disable-form'] = !column.disable_on_update_column
        end

        def _as_render_updated_columns?(form_columns, update_columns)
          form_columns && update_columns&.intersect?(form_columns)
        end
        private :_as_add_update_columns_options, :_as_render_updated_columns?
      end
    end
  end
end
