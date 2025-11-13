module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumnHelpers
      # This method decides which input to use for the given column.
      # It does not do any rendering. It only decides which method is responsible for rendering.
      def active_scaffold_input_for(column, scope = nil, options = nil)
        options ||= active_scaffold_input_options(column, scope)
        options = update_columns_options(column, scope, options)
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
          raise "Unknown form_ui `#{column.form_ui}' for column `#{column.name}'" if column.form_ui

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
        Rails.logger.error "#{e.class.name}: #{e.message} -- on the ActiveScaffold column = :#{column.name} in #{controller.class}"
        raise e
      end

      def active_scaffold_render_subform_column(column, scope, crud_type, readonly, add_class = false, record = nil) # rubocop:disable Metrics/ParameterLists
        if add_class
          col_class = []
          col_class << 'required' if column.required?(action_for_validation?(record))
          col_class << column.css_class unless column.css_class.nil? || column.css_class.is_a?(Proc)
          col_class << 'hidden' if column_renders_as(column) == :hidden
          col_class << 'checkbox' if column.form_ui == :checkbox
          col_class = col_class.join(' ')
        end
        if (readonly && !record.new_record?) || !record.authorized_for?(crud_type: crud_type, column: column.name)
          form_attribute(column, record, scope, true, col_class)
        else
          renders_as = column_renders_as(column)
          html = render_column(column, record, renders_as, scope, only_value: false, col_class: col_class)
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

      # the standard active scaffold options used for textual inputs
      def active_scaffold_input_text_options(options = {})
        options[:autocomplete] ||= 'off'
        options[:class] = "#{options[:class]} text-input".strip
        options
      end

      def action_for_validation?(record)
        record&.persisted? ? :update : :create
      end

      # the standard active scaffold options used for class, name and scope
      def active_scaffold_input_options(column, scope = nil, options = {})
        name = scope ? "record#{scope}[#{column.name}]" : "record[#{column.name}]"
        record = options[:object]

        # Add some HTML5 attributes for in-browser validation and better user experience
        if column.required?(action_for_validation?(record)) && (!@disable_required_for_new || scope.nil? || record&.persisted?)
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
        if scope
          subform_controller.active_scaffold_config.subform.columns.visible_columns_names
        elsif %i[new create edit update render_field].include? action_name.to_sym
          # disable update_columns for inplace_edit (GET render_field)
          return if action_name == 'render_field' && request.get?

          active_scaffold_config.send(record.new_record? ? :create : :update).columns.visible_columns_names
        end
      end

      def update_columns_options(column, scope, options, force = false, form_columns: nil, url_params: {})
        record = options[:object]
        subform_controller = controller.class.active_scaffold_controller_for(record.class) if scope
        if @main_columns && (scope.nil? || subform_controller == controller.class)
          form_columns ||= @main_columns.visible_columns_names
        end
        form_columns ||= current_form_columns(record, scope, subform_controller)
        if force || (form_columns && column.update_columns&.intersect?(form_columns))
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

          options[:class] = "#{options[:class]} update_form".strip
          options['data-update_url'] = url_for(url_params)
          options['data-update_send_form'] = column.send_form_on_update_column
          options['data-update_send_form_selector'] = column.options[:send_form_selector] if column.options[:send_form_selector]
          options['data-skip-disable-form'] = !column.disable_on_update_column
        end
        options
      end

      def field_attributes(column, record)
        {}
      end

      def render_subsection(column, record, scope, form_action, partial: 'form', subsection_id: nil, &)
        subsection_id ||= sub_section_id(sub_section: column.label)
        locals = {columns: column, form_action: form_action, scope: scope}
        header = as_element(:form_subsection_header) do
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
        elsif block_given?
          header << capture(subsection_id, &)
        else
          header << render(partial, locals.merge(subsection_id: subsection_id))
        end
      end

      def render_column(column, record, renders_as, scope = nil, only_value: false, col_class: nil, **subform_locals)
        if form_column_is_hidden?(column, record, scope)
          # creates an element that can be replaced by the update_columns routine,
          # but will not affect the value of the submitted form in this state:
          # <dl><input type="hidden" class="<%= column.name %>-input"></dl>
          content_tag :dl, style: 'display: none' do
            hidden_field_tag(nil, nil, class: "#{column.name}-input")
          end
        elsif (partial = override_form_field_partial(column))
          render partial, column: column, only_value: only_value, scope: scope, col_class: col_class, record: record
        elsif renders_as == :field || override_form_field?(column)
          form_attribute(column, record, scope, only_value, col_class)
        elsif renders_as == :subform
          render 'form_association', subform_locals.slice(:tabbed_by, :tab_value, :tab_id).merge(column: column, scope: scope, parent_record: record)
        else
          form_hidden_attribute(column, record, scope)
        end
      end

      def form_ui_class(form_ui) = form_ui

      def form_column_is_hidden?(column, record, scope = nil)
        if column.hide_form_column_if.respond_to?(:call)
          column.hide_form_column_if.call(record, column, scope)
        elsif column.hide_form_column_if.is_a?(Symbol)
          record.send(column.hide_form_column_if)
        else
          column.hide_form_column_if
        end
      end

      def form_attribute(column, record, scope = nil, only_value = false, col_class = nil)
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
          field = active_scaffold_input_for column, scope, column_options
        end
        if field
          field << loading_indicator_tag(action: :render_field, id: params[:id]) if column.update_columns
          description = column.description(record, scope)
          description = as_element(:form_field_description, description) if description.present?
        end

        label = label_tag(label_for(column, column_options), form_column_label(column, record, scope))
        label << h(' ') << link_to_visibility_toggle(collapsible_id) if collapsible_id
        form_attribute_html(column, label, field, description, attributes, collapsible_id)
      end

      def form_attribute_html(column, label, field, description, attributes, collapsible_id)
        field << description if description.present?
        content_tag :dl, content_tag(:dt, label) << content_tag(:dd, field, id: collapsible_id), attributes
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

      def form_hidden_attribute(column, record, scope = nil)
        content_tag :dl, style: 'display: none' do
          content_tag(:dt, '') <<
            content_tag(:dd, form_hidden_field(column, record, scope))
        end
      end

      def form_hidden_field(column, record, scope)
        options = active_scaffold_input_options(column, scope)
        if column.association&.collection?
          associated = record.send(column.name)
          if associated.blank?
            hidden_field_tag options[:name], '', options
          else
            options[:name] += '[]'
            fields = associated.map do |r|
              hidden_field_tag options[:name], r.id, options.merge(id: options[:id] + "_#{r.id}")
            end
            safe_join fields, ''
          end
        elsif column.association
          hidden_field_tag options[:name], record.send(column.name)&.id, options
        else
          hidden_field :record, column.name, options.merge(object: record)
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
      ## Form input methods
      ##

      def active_scaffold_grouped_options(column, select_options, optgroup)
        group_column = active_scaffold_config_for(column.association.klass).columns[optgroup]
        group_label = group_column.options[:label_method] if group_column
        group_label ||= group_column&.association ? :to_label : :to_s
        select_options.group_by(&optgroup.to_sym).collect do |group, options|
          [group.send(group_label), options.collect { |r| [r.send(column.options[:label_method] || :to_label), r.id] }]
        end
      end

      def active_scaffold_translate_select_options(options)
        options[:include_blank] = as_(options[:include_blank].to_s) if options[:include_blank].is_a? Symbol
        options[:prompt] = as_(options[:prompt].to_s) if options[:prompt].is_a? Symbol
        options
      end

      def active_scaffold_select_name_with_multiple(options)
        return if !options[:multiple] || options[:name].to_s.ends_with?('[]')

        options[:name] = "#{options[:name]}[]"
      end

      def active_scaffold_input_singular_association(column, html_options, options = {}, ui_options: column.options)
        record = html_options.delete(:object)
        associated = html_options.include?(:associated) ? html_options.delete(:associated) : record.send(column.association.name)

        helper_method = association_helper_method(column.association, :sorted_association_options_find)
        select_options = send(helper_method, column.association, nil, record)
        select_options.unshift(associated) if associated&.persisted? && select_options.exclude?(associated)

        method = column.name
        options.merge! selected: associated&.id, include_blank: as_(:_select_), object: record

        html_options.merge!(ui_options[:html_options] || {})
        options.merge!(ui_options)
        html_options.delete(:multiple) # no point using multiple in a form for singular assoc, but may be set for field search
        active_scaffold_translate_select_options(options)

        html =
          if (optgroup = options.delete(:optgroup))
            select(:record, method, active_scaffold_grouped_options(column, select_options, optgroup), options, html_options)
          else
            collection_select(:record, method, select_options, :id, ui_options[:label_method] || :to_label, options, html_options)
          end
        html << active_scaffold_refresh_link(column, html_options, record, ui_options) if ui_options[:refresh_link]
        html << active_scaffold_add_new(column, record, html_options, ui_options: ui_options) if ui_options[:add_new]
        html
      end

      def active_scaffold_new_record_klass(column, record, **options)
        if column.association.polymorphic? && column.association.belongs_to?
          type = record.send(column.association.foreign_type)
          type_options = options[:types]
          column.association.klass(record) if type.present? && (type_options.nil? || type_options.include?(type))
        else
          column.association.klass
        end
      end

      def active_scaffold_add_new(column, record, html_options, ui_options: column.options, skip_link: false)
        options = ui_options[:add_new] == true ? {} : ui_options[:add_new]
        case options[:mode]
        when nil, :subform
          active_scaffold_new_record_subform(column, record, html_options, options: options, skip_link: skip_link)
        when :popup
          active_scaffold_new_record_popup(column, record, html_options, options: options) unless skip_link
        else
          raise ArgumentError, "unsupported mode for add_new: #{options[:mode].inspect}"
        end
      end

      def active_scaffold_new_record_url_options(column, record)
        if column.association.reverse
          constraint = [record.id]
          constraint.unshift record.class.name if column.association.reverse_association.polymorphic?
          {embedded: {constraints: {column.association.reverse => constraint}}}
        else
          raise "can't add constraint to create new record with :popup, no reverse association for " \
                "\"#{column.name}\" in #{column.association.klass}, add the reverse association " \
                'or override active_scaffold_new_record_url_options helper.'
        end
      end

      def active_scaffold_new_record_popup(column, record, html_options, options: {})
        klass = send(override_helper_per_model(:active_scaffold_new_record_klass, record.class), column, record, **options)
        klass = nil if options[:security_method] && !controller.send(options[:security_method])
        klass = nil if klass && options[:security_method].nil? && !klass.authorized_for?(crud_type: :create)
        return h('') unless klass

        link_text = active_scaffold_add_new_text(options, :add_new_text, :add)
        url_options_helper = override_helper_per_model(:active_scaffold_new_record_url_options, record.class)
        url_options = send(url_options_helper, column, record)
        url_options[:controller] ||= active_scaffold_controller_for(klass).controller_path
        url_options[:action] ||= :new
        url_options[:from_field] ||= html_options[:id]
        url_options[:parent_model] ||= record.class.name
        url_options[:parent_column] ||= column.name
        url_options.reverse_merge! options[:url_options] if options[:url_options]
        link_to(link_text, url_options, remote: true, data: {position: :popup}, class: 'as_action')
      end

      def active_scaffold_new_record_subform(column, record, html_options, options: {}, new_record_attributes: nil, locals: {}, skip_link: false)
        klass = send(override_helper_per_model(:active_scaffold_new_record_klass, record.class), column, record, **options)
        return content_tag(:div, '') unless klass

        subform_attrs = active_scaffold_subform_attributes(column, nil, klass, ui_options: options)
        if record.send(column.name)&.new_record?
          new_record = record.send(column.name)
        else
          subform_attrs[:style] = 'display: none'
        end
        subform_attrs[:class] << ' optional'
        scope = html_options[:name].scan(/record(.*)\[#{column.name}\]/).dig(0, 0)
        new_record ||= klass.new(new_record_attributes)
        locals = locals.reverse_merge(column: column, parent_record: record, associated: [], show_blank_record: new_record, scope: scope)
        subform = render(partial: subform_partial_for_column(column, klass, ui_options: options), locals: locals)
        if options[:hide_subgroups]
          toggable_id = "#{sub_form_id(association: column.name, id: record.id || generated_id(record) || 99_999_999_999)}-div"
          subform << link_to_visibility_toggle(toggable_id, default_visible: false)
        end
        html = content_tag(:div, subform, subform_attrs)
        return html if skip_link

        html << active_scaffold_show_new_subform_link(column, record, html_options[:id], subform_attrs[:id], options: options)
      end

      def active_scaffold_add_new_text(options, key, default)
        text = options[key] unless options == true
        return text if text.is_a? String

        as_(text || default)
      end

      def active_scaffold_show_new_subform_link(column, record, select_id, subform_id, options: {})
        add_existing = active_scaffold_add_new_text(options, :add_existing_text, :add_existing)
        create_new = active_scaffold_add_new_text(options, :add_new_text, :create_new)
        data = {select_id: select_id, subform_id: subform_id, subform_text: add_existing, select_text: create_new}
        label = data[record.send(column.name)&.new_record? ? :subform_text : :select_text]
        link_to(label, '#', data: data, class: 'show-new-subform')
      end

      def active_scaffold_file_with_remove_link(column, options, content, remove_file_prefix, controls_class, ui_options: column.options, &block)
        options = active_scaffold_input_text_options(options.merge(ui_options))
        if content
          active_scaffold_file_with_content(column, content, options, remove_file_prefix, controls_class, &block)
        else
          file_field(:record, column.name, options)
        end
      end

      def active_scaffold_file_with_content(column, content, options, remove_file_prefix, controls_class)
        required = options.delete(:required)
        js_remove_file_code = "jQuery(this).prev().val('true'); jQuery(this).parent().hide().next().show()#{".find('input').attr('required', 'required')" if required}; return false;"
        js_dont_remove_file_code = "jQuery(this).parents('div.#{controls_class}').find('input.remove_file').val('false'); return false;"

        object_name, method = options[:name].split(/\[(#{column.name})\]/)
        method.sub!(/#{column.name}/, "#{remove_file_prefix}\\0")
        fields = block_given? ? yield : ''
        link_key = options[:multiple] ? :remove_files : :remove_file
        input = file_field(:record, column.name, options.merge(onchange: js_dont_remove_file_code))
        content_tag(:div, class: controls_class) do
          content_tag(:div) do
            safe_join [content, ' | ', fields,
                       hidden_field(object_name, method, value: 'false', class: 'remove_file'),
                       content_tag(:a, as_(link_key), href: '#', onclick: js_remove_file_code)]
          end << content_tag(:div, input, style: 'display: none')
        end
      end

      def active_scaffold_refresh_link(column, html_options, record, ui_options = {})
        link_options = {object: record}
        if html_options['data-update_url']
          link_options['data-update_send_form'] = html_options['data-update_send_form']
          link_options['data-update_send_form_selector'] = html_options['data-update_send_form_selector']
        else
          scope = html_options[:name].scan(/^record((\[[^\]]*\])*)\[#{column.name}\]/).dig(0, 0) if html_options[:name]
          link_options = update_columns_options(column, scope.presence, link_options, true)
        end
        link_options[:class] = 'refresh-link'
        if ui_options[:refresh_link].is_a?(Hash)
          text = ui_options.dig(:refresh_link, :text)
          text = as_(text) if text.is_a?(Symbol)
          link_options.merge! ui_options[:refresh_link].except(:text)
        end
        link_to(text || as_(:refresh), link_options.delete('data-update_url') || html_options['data-update_url'], link_options.except(:object))
      end

      def active_scaffold_plural_association_options(column, record = nil)
        associated_options = record.send(column.association.name)
        helper_method = association_helper_method(column.association, :sorted_association_options_find)
        [associated_options, associated_options | send(helper_method, column.association, nil, record)]
      end

      def active_scaffold_input_plural_association(column, options, ui_options: column.options)
        record = options.delete(:object)
        associated_options, select_options = active_scaffold_plural_association_options(column, record)

        html =
          if options[:multiple] || ui_options.dig(:html_options, :multiple)
            html_options = options.merge(ui_options[:html_options] || {})
            active_scaffold_select_name_with_multiple html_options
            collection_select(:record, column.name, select_options, :id, ui_options[:label_method] || :to_label, ui_options.merge(object: record), html_options)
          elsif select_options.empty?
            content_tag(:span, as_(:no_options), class: "#{options[:class]} no-options", id: options[:id]) <<
              hidden_field_tag("#{options[:name]}[]", '', id: nil)
          else
            active_scaffold_checkbox_list(column, select_options, associated_options.collect(&:id), options, ui_options: ui_options)
          end
        html << active_scaffold_refresh_link(column, options, record, ui_options) if ui_options[:refresh_link]
        html
      end

      def active_scaffold_input_draggable(column, options, ui_options: column.options)
        active_scaffold_input_plural_association(column, options.merge(draggable_lists: true), ui_options: ui_options)
      end

      def active_scaffold_checkbox_option(option, label_method, associated_ids, checkbox_options, li_options = {})
        content_tag(:li, li_options) do
          option_id = option.is_a?(Array) ? option[1] : option.id
          label = option.is_a?(Array) ? option[0] : option.send(label_method)
          check_box_tag(checkbox_options[:name], option_id, associated_ids.include?(option_id), checkbox_options) <<
            content_tag(:label, label, for: checkbox_options[:id])
        end
      end

      def active_scaffold_check_all_buttons(column, options, ui_options: column.options)
        content_tag(:div, class: 'check-buttons') do
          link_to(as_(:check_all), '#', class: 'check-all') <<
            link_to(as_(:uncheck_all), '#', class: 'uncheck-all')
        end
      end

      def active_scaffold_checkbox_list(column, select_options, associated_ids, options, ui_options: column.options)
        label_method = ui_options[:label_method] || :to_label
        html = active_scaffold_check_all_buttons(column, options, ui_options: ui_options)
        html << hidden_field_tag("#{options[:name]}[]", '', id: nil)
        draggable = options.delete(:draggable_lists) || ui_options[:draggable_lists]
        html << content_tag(:ul, options.merge(class: "#{options[:class]} checkbox-list#{' draggable-lists' if draggable}")) do
          content = []
          select_options.each_with_index do |option, i|
            content << active_scaffold_checkbox_option(option, label_method, associated_ids, name: "#{options[:name]}[]", id: "#{options[:id]}_#{i}_id")
          end
          safe_join content
        end
        html
      end

      def active_scaffold_translated_option(column, text, value = nil)
        value = text if value.nil?
        [(text.is_a?(Symbol) ? column.active_record_class.human_attribute_name(text) : text), value]
      end

      def active_scaffold_enum_options(column, record = nil, ui_options: column.options)
        ui_options[:options]
      end

      def active_scaffold_input_enum(column, html_options, options = {}, ui_options: column.options)
        record = html_options.delete(:object)
        options[:selected] = record.send(column.name)
        options[:object] = record
        enum_options_method = override_helper_per_model(:active_scaffold_enum_options, record.class)
        options_for_select = send(enum_options_method, column, record, ui_options: ui_options).collect do |text, value|
          active_scaffold_translated_option(column, text, value)
        end
        html_options.merge!(ui_options[:html_options] || {})
        options.merge!(ui_options)
        active_scaffold_select_name_with_multiple html_options
        active_scaffold_translate_select_options(options)
        html = select(:record, column.name, options_for_select, options, html_options)
        html << active_scaffold_refresh_link(column, html_options, record, ui_options) if ui_options[:refresh_link]
        html
      end

      def active_scaffold_input_select(column, html_options, ui_options: column.options)
        if column.association&.singular?
          active_scaffold_input_singular_association(column, html_options, ui_options: ui_options)
        elsif column.association&.collection?
          active_scaffold_input_plural_association(column, html_options, ui_options: ui_options)
        else
          active_scaffold_input_enum(column, html_options, ui_options: ui_options)
        end
      end

      def active_scaffold_input_select_multiple(column, options, ui_options: column.options)
        active_scaffold_input_select(column, options.merge(multiple: true), ui_options: ui_options)
      end

      def active_scaffold_radio_option(option, selected, column, radio_options, ui_options: column.options)
        if column.association
          label_method = ui_options[:label_method] || :to_label
          text = option.send(label_method)
          value = option.id
          checked = {checked: selected == value}
        else
          text, value = active_scaffold_translated_option(column, *option)
        end

        id_key = radio_options[:'data-id'] ? :'data-id' : :id
        radio_options = radio_options.merge(id_key => "#{radio_options[id_key]}-#{value.to_s.parameterize}")
        radio_options.merge!(checked) if checked
        content_tag(:label, radio_button(:record, column.name, value, radio_options) + text)
      end

      def active_scaffold_input_radio(column, html_options, ui_options: column.options)
        record = html_options[:object]
        html_options.merge!(ui_options[:html_options] || {})
        options =
          if column.association
            helper_method = association_helper_method(column.association, :sorted_association_options_find)
            send(helper_method, column.association, nil, record)
          else
            enum_options_method = override_helper_per_model(:active_scaffold_enum_options, record.class)
            send(enum_options_method, column, record, ui_options: ui_options)
          end

        selected = record.send(column.association.name) if column.association
        selected_id = selected&.id
        if options.present?
          if ui_options[:add_new]
            html_options[:data] ||= {}
            html_options[:data][:subform_id] = active_scaffold_subform_attributes(column, ui_options: ui_options)[:id]
            radio_html_options = html_options.merge(class: "#{html_options[:class]} hide-new-subform")
          else
            radio_html_options = html_options
          end
          radios = options.map do |option|
            active_scaffold_radio_option(option, selected_id, column, radio_html_options, ui_options: ui_options)
          end
          if ui_options[:include_blank]
            label = ui_options[:include_blank]
            label = as_(ui_options[:include_blank]) if ui_options[:include_blank].is_a?(Symbol)
            radio_id = "#{html_options[:id]}-"
            radios.prepend content_tag(:label, radio_button(:record, column.name, '', html_options.merge(id: radio_id)) + label)
          end
          if ui_options[:add_new]
            if ui_options[:add_new] == true || ui_options[:add_new][:mode].in?([nil, :subform])
              create_new = content_tag(:label) do
                radio_button_tag(html_options[:name], '', selected&.new_record?, html_options.merge(
                  id: "#{html_options[:id]}-create_new", class: "#{html_options[:class]} show-new-subform"
                ).except(:object)) <<
                  active_scaffold_add_new_text(ui_options[:add_new], :add_new_text, :create_new)
              end
              radios << create_new
              skip_link = true
            else
              ui_options = ui_options.merge(add_new: ui_options[:add_new].merge(
                url_options: {
                  parent_scope: html_options[:name].gsub(/^record|\[[^\]]*\]$/, '').presence,
                  radio_data: html_options.slice(*html_options.keys.grep(/^data-update_/))
                }
              ))
              radios << content_tag(:span, '', class: 'new-radio-container', id: html_options[:id])
            end
            radios << active_scaffold_add_new(column, record, html_options, ui_options: ui_options, skip_link: skip_link)
          end
          safe_join radios
        else
          html = content_tag(:span, as_(:no_options), class: "#{html_options[:class]} no-options", id: html_options[:id])
          html << hidden_field_tag(html_options[:name], '', id: nil)
          html << active_scaffold_add_new(column, record, html_options, ui_options: ui_options) if ui_options[:add_new]
          html
        end
      end

      def active_scaffold_input_checkbox(column, options, ui_options: column.options)
        check_box(:record, column.name, options.merge(ui_options))
      end

      def active_scaffold_input_password(column, options, ui_options: column.options)
        active_scaffold_text_input :password_field, column, options.reverse_merge(autocomplete: 'new-password'), ui_options: ui_options
      end

      def active_scaffold_input_textarea(column, options, ui_options: column.options)
        text_area(:record, column.name, options.merge(cols: ui_options[:cols], rows: ui_options[:rows], size: ui_options[:size]))
      end

      def active_scaffold_input_virtual(column, options)
        active_scaffold_text_input :text_field, column, options
      end

      # Some fields from HTML5 (primarily for using in-browser validation)
      # Sadly, many of them lacks browser support

      # A text box, that accepts only valid email address (in-browser validation)
      def active_scaffold_input_email(column, options, ui_options: column.options)
        active_scaffold_text_input :email_field, column, options, ui_options: ui_options
      end

      # A text box, that accepts only valid URI (in-browser validation)
      def active_scaffold_input_url(column, options, ui_options: column.options)
        active_scaffold_text_input :url_field, column, options, ui_options: ui_options
      end

      # A text box, that accepts only valid phone-number (in-browser validation)
      def active_scaffold_input_telephone(column, options, ui_options: column.options)
        active_scaffold_text_input :telephone_field, column, options, :format, ui_options: ui_options
      end

      # A spinbox control for number values (in-browser validation)
      def active_scaffold_input_number(column, options, ui_options: column.options)
        active_scaffold_number_input :number_field, column, options, :format, ui_options: ui_options
      end

      # A slider control for number values (in-browser validation)
      def active_scaffold_input_range(column, options, ui_options: column.options)
        active_scaffold_number_input :range_field, column, options, :format, ui_options: ui_options
      end

      # A slider control for number values (in-browser validation)
      def active_scaffold_number_input(method, column, options, remove_options = nil, ui_options: column.options)
        options = numerical_constraints_for_column(column, options)
        active_scaffold_text_input method, column, options, remove_options, ui_options: ui_options
      end

      def active_scaffold_text_input(method, column, options, remove_options = nil, ui_options: column.options)
        options = active_scaffold_input_text_options(options)
        options = options.merge(ui_options)
        options = options.except(*remove_options) if remove_options.present?
        send method, :record, column.name, options
      end

      # A color picker
      def active_scaffold_input_color(column, options, ui_options: column.options)
        html = []
        options = active_scaffold_input_text_options(options)
        if column.null?
          no_color = options[:object].send(column.name).nil?
          method = no_color ? :hidden_field : :color_field
          html << content_tag(:label, check_box_tag('disable', '1', no_color, id: nil, name: nil, class: 'no-color') << " #{as_ ui_options[:no_color] || :no_color}")
        else
          method = :color_field
        end
        html << send(method, :record, column.name, options.merge(ui_options).except(:format, :no_color))
        safe_join html
      end

      #
      # Column.type-based inputs
      #

      def active_scaffold_input_boolean(column, html_options, ui_options: column.options)
        record = html_options.delete(:object)
        html_options.merge!(ui_options[:html_options] || {})

        options = {selected: record.send(column.name), object: record}
        options[:include_blank] = :_select_ if column.null?
        options.merge!(ui_options)
        active_scaffold_translate_select_options(options)

        options_for_select = [[as_(:true), true], [as_(:false), false]] # rubocop:disable Lint/BooleanSymbol
        select(:record, column.name, options_for_select, options, html_options)
      end

      def active_scaffold_input_date(column, options, ui_options: column.options)
        active_scaffold_text_input :date_field, column, options, ui_options: ui_options
      end

      def active_scaffold_input_time(column, options, ui_options: column.options)
        active_scaffold_text_input :time_field, column, options, ui_options: ui_options
      end

      def active_scaffold_input_datetime(column, options, ui_options: column.options)
        active_scaffold_text_input :datetime_local_field, column, options, ui_options: ui_options
      end

      def active_scaffold_input_month(column, options, ui_options: column.options)
        active_scaffold_text_input :month_field, column, options, ui_options: ui_options
      end

      def active_scaffold_input_week(column, options, ui_options: column.options)
        active_scaffold_text_input :week_field, column, options, ui_options: ui_options
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

      def column_scope(column, scope = nil, record = nil)
        if column.association&.collection?
          "#{scope}[#{column.name}][#{record.id || generate_temporary_id(record)}]"
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
          helper_method = association_helper_method(column.association, :sorted_association_options_find)
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
