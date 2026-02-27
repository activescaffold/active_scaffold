# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumnHelpers
      # This method decides which input to use for the given column.
      # It does not do any rendering. It only decides which method is responsible for rendering.
      def active_scaffold_input_for(column, scope = nil, options = nil, form_columns: nil)
        options ||= active_scaffold_input_options(column, scope)
        options = update_columns_options(column, scope, options, form_columns: form_columns)
        active_scaffold_render_input(column, options)
      end

      def active_scaffold_render_input(column, options)
        record = options[:object]

        # first, check if the dev has created an override for this specific field
        if (method = override_form_field(column))
          send(method, record, options)

        # second, check if the dev has specified a valid form_ui for this column
        elsif column.form_ui && (method = override_input(column.form_ui))
          send(method, column, options, ui_options: (column.form_ui_options || column.options).except(:collapsible))

        elsif column.association
          # if we get here, it's because the column has a form_ui but not one ActiveScaffold knows about.
          raise ArgumentError, "Unknown form_ui `#{column.form_ui}' for column `#{column.name}'" if column.form_ui

          # its an association and nothing is specified, we will assume form_ui :select
          active_scaffold_input_select(column, options)

        elsif column.virtual?
          options[:value] = format_number_value(record.send(column.name), column.options) if column.number?
          active_scaffold_input_virtual(column, options)

        elsif (method = override_input(column.column_type)) # regular model attribute column
          # if we (or someone else) have created a custom render option for the column type, use that
          send(method, column, options)

        else # final ultimate fallback: use rails' generic input method
          # for textual fields we pass different options
          options = active_scaffold_input_text_options(options) if column.text? || column.number?
          if column.column_type == :string && options[:maxlength].blank?
            options[:maxlength] = column.type_for_attribute.limit
            options[:size] ||= options[:maxlength].to_i > 30 ? 30 : options[:maxlength]
          end
          options[:value] = format_number_value(record.send(column.name), column.options) if column.number?
          text_field(:record, column.name, options.merge(column.options).except(:format))
        end
      rescue StandardError => e
        message = "on the ActiveScaffold column = :#{column.name} in #{controller.class}"
        ActiveScaffold.log_exception(e, message)
        raise e.class, "#{e.message} -- #{message}", e.backtrace
      end

      def active_scaffold_render_subform_column(column, scope, crud_type, readonly, add_class = false, record = nil, form_columns: nil) # rubocop:disable Metrics/ParameterLists
        if add_class
          col_class = []
          col_class << 'required' if column.required?(action_for_validation(record))
          col_class << column.css_class unless column.css_class.nil? || column.css_class.is_a?(Proc)
          col_class << 'hidden' if column_renders_as(column) == :hidden
          col_class << 'checkbox' if column.form_ui == :checkbox
          col_class = col_class.join(' ')
        end
        if (readonly && !record.new_record?) || !record.authorized_for?(crud_type: crud_type, column: column.name)
          form_attribute(column, record, scope, true, col_class)
        else
          renders_as = column_renders_as(column)
          html = render_column(column, record, renders_as, scope, only_value: false, col_class: col_class, form_columns: form_columns)
          html = content_tag(:div, html, active_scaffold_subform_attributes(column)) if renders_as == :subform
          html
        end
      end

      def active_scaffold_subform_attributes(column, column_css_class = nil, klass = nil, tab_id: nil, ui_options: column.options)
        {
          class: "sub-form #{ui_options[:layout] || active_scaffold_config_for(klass || column.association.klass).subform.layout}-sub-form #{column_css_class} #{column.name}-sub-form",
          id: sub_form_id(association: column.name, tab_id: tab_id)
        }
      end

      def active_scaffold_subform_record_actions(association_column, record, locked, scope)
        return unless association_column.association.collection? && !locked

        auth = %i[destroy delete_all delete].exclude?(association_column.association.dependent)
        auth, reason = record.authorized_for?(crud_type: :delete, reason: true) unless auth
        if auth
          link_to(as_(:remove), '#', class: 'destroy')
        else
          content_tag :span, reason, class: 'destroy reason'
        end
      end

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

        # Add some HTML5 attributes for in-browser validation and better user experience
        if column.required?(action_for_validation(record)) && (!@disable_required_for_new || scope.nil? || record&.persisted?)
          options[:required] = true
        end
        options[:placeholder] = column.placeholder if column.placeholder.present?

        # Fix for keeping unique IDs in subform
        id_control = "record_#{column.name}_#{[params[:eid], params[:parent_id] || params[:id]].compact.join '_'}"
        id_control += scope_id(scope) if scope

        classes = "#{column.name}-input"
        classes += ' numeric-input' if column.number?

        collapsible_id = "container_#{id_control}" if (column.form_ui_options || column.options)[:collapsible]

        {name: name, class: classes, id: id_control, collapsible_id: collapsible_id}.merge(options)
      end

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

      def update_columns_options(column, scope, options, force = false, form_columns: nil, url_params: {})
        record = options[:object]
        subform_controller = controller.class.active_scaffold_controller_for(record.class) if scope
        form_columns ||= current_form_columns(record, scope, subform_controller)
        update_columns = column.update_columns&.flat_map { |col| col.is_a?(Hash) ? col.keys : col }
        force = true if update_columns&.include?(:__root__)

        if force || (form_columns && update_columns&.intersect?(form_columns))
          url_params = url_options_for_render_field(column, record, scope, subform_controller, url_params)
          options[:class] = "#{options[:class]} update_form".strip
          options['data-update_url'] = url_for(url_params)
          options['data-update_send_form'] = column.update_columns&.any?(Hash) || column.send_form_on_update_column
          options['data-update_send_form_selector'] = column.options[:send_form_selector] if column.options[:send_form_selector]
          options['data-skip-disable-form'] = !column.disable_on_update_column
        end
        options
      end

      def field_attributes(column, record)
        {}
      end

      def render_subsection(column, record, scope, form_action, partial: 'form')
        subsection_id = sub_section_id(sub_section: column.label)
        locals = {columns: column, form_action: form_action, scope: scope}
        header = content_tag(:h5) do
          h(column.label) <<
            link_to_visibility_toggle(subsection_id, default_visible: !column.collapsed)
        end
        if column.tabbed_by
          locals[:tabbed_by] = column.tabbed_by
          header << content_tag(:div, id: subsection_id) do
            active_scaffold_tabbed_by(column, record, scope, subsection_id) do |tab_value, tab_id|
              render partial, locals.merge(subsection_id: "#{subsection_id}-#{tab_id}", tab_id: tab_id, tab_value: tab_value)
            end
          end
        else
          header << render(partial, locals.merge(subsection_id: subsection_id))
        end
      end

      def render_column(column, record, renders_as, scope = nil, only_value: false, col_class: nil, form_columns: nil, **subform_locals)
        hide_column, clear = form_column_is_hidden?(column, record, scope)
        if hide_column
          if clear
            form_hidden_attribute(column, record, scope, true)
          else
            # creates an element that can be replaced by the update_columns routine,
            # but will not affect the value of the submitted form in this state:
            # <dl><input type="hidden" class="<%= column.name %>-input"></dl>
            content_tag :dl, style: 'display: none' do
              hidden_field_tag(nil, nil, class: "#{column.name}-input")
            end
          end
        elsif (partial = override_form_field_partial(column))
          render partial, column: column, only_value: only_value, scope: scope, col_class: col_class, record: record, form_columns: form_columns
        elsif renders_as == :field || override_form_field?(column)
          form_attribute(column, record, scope, only_value, col_class, form_columns: form_columns)
        elsif renders_as == :subform
          render 'form_association', subform_locals.slice(:tabbed_by, :tab_value, :tab_id).merge(column: column, scope: scope, parent_record: record)
        else
          form_hidden_attribute(column, record, scope)
        end
      end

      def form_column_is_hidden?(column, record, scope = nil) # rubocop:disable Naming/PredicateMethod
        if column.clear_form_column_if.nil?
          condition_to_hide = column.hide_form_column_if
          clear = false
        else
          condition_to_hide = column.clear_form_column_if
          clear = true
        end
        hide =
          if condition_to_hide.respond_to?(:call)
            condition_to_hide.call(record, column, scope)
          elsif condition_to_hide.is_a?(Symbol)
            record.send(condition_to_hide)
          else
            condition_to_hide
          end
        [hide, clear]
      end

      def column_description(column, record, scope = nil)
        desc = column.description(record, scope)
        content_tag(:span, h(desc) + content_tag(:span, nil, class: 'close'), class: 'description') if desc.present?
      end

      def form_attribute(column, record, scope = nil, only_value = false, col_class = nil, form_columns: nil)
        column_options = active_scaffold_input_options(column, scope, object: record)
        collapsible_id = column_options.delete :collapsible_id
        attributes = field_attributes(column, record)
        attributes[:class] = "#{attributes[:class]} #{col_class}" if col_class.present?
        if only_value
          field = content_tag(:span, show_column_value(record, column), column_options.except(:name, :object))
          if column.association.nil? || column.association.belongs_to?
            # hidden field probably not needed, but leaving it just in case
            # but it isn't working for assocations which are not belongs_to
            method = column.association ? column.association.foreign_key : column.name
            field << hidden_field(:record, method, column_options)
          end
        else
          field = active_scaffold_input_for column, scope, column_options, form_columns: form_columns
        end
        if field
          field << loading_indicator_tag(action: :render_field, id: params[:id]) if column.update_columns
          desc = column_description(column, record, scope)
          field << desc if desc.present?
        end

        label = label_tag(label_for(column, column_options), form_column_label(column, record, scope))
        label << h(' ') << link_to_visibility_toggle(collapsible_id) if collapsible_id
        content_tag :dl, attributes do
          content_tag(:dt, label) << content_tag(:dd, field, id: collapsible_id)
        end
      end

      def label_for(column, options)
        options[:id] unless column.form_ui == :select && column.association&.collection?
      end

      def form_column_label(column, record = nil, scope = nil)
        column.label(record, scope)
      end

      def subform_label(column, hidden)
        column.label unless hidden
      end

      def form_hidden_attribute(column, record, scope = nil, clear = false)
        content_tag :dl, style: 'display: none' do
          content_tag(:dt, '') <<
            content_tag(:dd, form_hidden_field(column, record, scope, clear))
        end
      end

      def form_hidden_field(column, record, scope, clear = false)
        options = active_scaffold_input_options(column, scope)
        value = record.send(column.name) unless clear
        if column.association&.collection?
          options[:name] += '[]'
          if value.blank?
            hidden_field_tag options[:name], '', options
          else
            fields = value.map do |r|
              hidden_field_tag options[:name], r.id, options.merge(id: options[:id] + "_#{r.id}")
            end
            safe_join fields, ''
          end
        elsif column.association
          hidden_field_tag options[:name], value&.id, options
        else
          options[:name] += '[]' if active_scaffold_column_expect_array?(column)
          hidden_field_tag options[:name], value, options
        end
      end

      def active_scaffold_column_expect_array?(column)
        ui_options = column.form_ui_options || column.options
        case column.form_ui
        when :select
          column.association&.collection? || ui_options[:multiple]
        when :select_multiple, :checkboxes, :draggable
          true
        end
      end

      # Should this column be displayed in the subform?
      def in_subform?(column, parent_record, parent_column)
        return true unless column.association

        if column.association.reverse.nil?
          # Polymorphic associations can't appear because they *might* be the reverse association
          return false if column.association.polymorphic?

          # A column shouldn't be in the subform if it's the reverse association to the parent
          !column.association.inverse_for?(parent_record.class)
        elsif column.association.reverse == parent_column.name
          if column.association.polymorphic?
            column.association.name != parent_column.association.as
          else
            !column.association.inverse_for?(parent_record.class)
          end
        else
          true
        end
      end

      def column_show_add_existing(column, record = nil)
        column.allow_add_existing && options_for_association_count(column.association, record).positive?
      end

      def column_show_add_new(column, associated, record)
        assoc = column.association
        value = assoc.singular?
        value ||= assoc.collection? && !assoc.readonly? && (!assoc.through? || !assoc.through_reflection.collection?)
        value &&= false unless assoc.klass.authorized_for?(crud_type: :create)
        value
      end

      ##
      ## Form column override signatures
      ##

      def partial_for_model(model, partial)
        controller = active_scaffold_controller_for(model)
        while controller.uses_active_scaffold?
          path = File.join(controller.controller_path, partial)
          return path if template_exists?(path, true)

          controller = controller.superclass
        end
        nil
      end

      # add functionality for overriding subform partials from association class path
      def override_subform_partial(column, subform_partial)
        partial_for_model(column.association.klass, subform_partial) if column_renders_as(column) == :subform
      end

      # the naming convention for overriding form fields with helpers
      def override_form_field_partial(column)
        partial_for_model(column.active_record_class, "#{clean_column_name(column.name)}_form_column")
      end

      def override_form_field(column)
        override_helper column, 'form_column'
      end
      alias override_form_field? override_form_field

      # the naming convention for overriding form input types with helpers
      def override_input(form_ui)
        method = "active_scaffold_input_#{form_ui}"
        method if respond_to? method
      end
      alias override_input? override_input

      def subform_partial_for_column(column, klass = nil, ui_options: column.options)
        subform_partial = "#{ui_options[:layout] || active_scaffold_config_for(klass || column.association.klass).subform.layout}_subform"
        override_subform_partial(column, subform_partial) || subform_partial
      end

      ##
      ## Macro-level rendering decisions for columns
      ##

      def column_renders_as(column)
        if column.respond_to? :each
          :subsection
        elsif column.active_record_class.locking_column.to_s == column.name.to_s || column.form_ui == :hidden
          :hidden
        elsif column.association.nil? || column.form_ui || active_scaffold_config_for(column.association.klass).actions.exclude?(:subform) || override_form_field?(column)
          :field
        else
          :subform
        end
      end

      def column_scope(column, scope = nil, record = nil, generated_id = nil)
        if column.association&.collection?
          "#{scope}[#{column.name}][#{record.id || generate_temporary_id(record, generated_id)}]"
        else
          "#{scope}[#{column.name}]"
        end
      end

      def active_scaffold_add_existing_input(options)
        record = options.delete(:object)
        if controller.respond_to?(:record_select_config, true)
          remote_controller = active_scaffold_controller_for(record_select_config.model).controller_path
          options[:controller] = remote_controller
          options.merge!(active_scaffold_input_text_options)
          record_select_field(options[:name], nil, options)
        else
          helper_method = association_helper_method(nested.association, :sorted_association_options_find)
          select_options = send(helper_method, nested.association, nil, record)
          select_options ||= active_scaffold_config.model.all
          select_options = options_from_collection_for_select(select_options, :id, :to_label)
          select_tag 'associated_id', (content_tag(:option, as_(:_select_), value: '') + select_options) unless select_options.empty?
        end
      end

      def active_scaffold_add_existing_label
        if controller.respond_to?(:record_select_config, true)
          record_select_config.model.model_name.human
        else
          active_scaffold_config.model.model_name.human
        end
      end

      # Try to get numerical constraints from model's validators
      def column_numerical_constraints(column, options)
        validators = column.active_record_class.validators.select do |v|
          v.is_a?(ActiveModel::Validations::NumericalityValidator) &&
            v.attributes.include?(column.name) &&
            !v.options[:if] && !v.options[:unless]
        end

        equal_validator = validators.find { |v| v.options[:equal_to] }
        # If there is equal_to constraint - use it (unless otherwise specified by user)
        if equal_validator && !(options[:min] || options[:max])
          equal_to = equal_validator.options[:equal_to]
          return {min: equal_to, max: equal_to}
        end

        numerical_constraints = {}

        # find minimum and maximum from validators
        # we can safely modify :min and :max by 1 for :greater_tnan or :less_than value only for integer values
        only_integer = column.column_type == :integer if column.column
        only_integer ||= validators.find { |v| v.options[:only_integer] }.present?
        margin = only_integer ? 1 : 0

        # Minimum
        unless options[:min]
          min = validators.filter_map { |v| v.options[:greater_than_or_equal_to] }.max
          greater_than = validators.filter_map { |v| v.options[:greater_than] }.max
          numerical_constraints[:min] = [min, (greater_than + margin if greater_than)].compact.max
        end

        # Maximum
        unless options[:max]
          max = validators.filter_map { |v| v.options[:less_than_or_equal_to] }.min
          less_than = validators.filter_map { |v| v.options[:less_than] }.min
          numerical_constraints[:max] = [max, (less_than - margin if less_than)].compact.min
        end

        # Set step = 2 for column values restricted to be odd or even (but only if minimum is set)
        unless options[:step]
          only_odd_valid  = validators.any? { |v| v.options[:odd] }
          only_even_valid = validators.any? { |v| v.options[:even] } unless only_odd_valid
          if !only_integer
            numerical_constraints[:step] ||= "0.#{'0' * (column.column.scale - 1)}1" if column.column&.scale.to_i.positive?
          elsif options[:min].respond_to?(:even?) && (only_odd_valid || only_even_valid)
            numerical_constraints[:step] = 2
            numerical_constraints[:min] += 1 if only_odd_valid  && options[:min].even?
            numerical_constraints[:min] += 1 if only_even_valid && options[:min].odd?
          end
          numerical_constraints[:step] ||= 'any' unless only_integer
        end

        numerical_constraints
      end

      def numerical_constraints_for_column(column, options)
        constraints = Rails.cache.fetch("#{column.cache_key}#numerical_constraints") do
          column_numerical_constraints(column, options)
        end
        constraints.merge(options)
      end
    end
  end
end
