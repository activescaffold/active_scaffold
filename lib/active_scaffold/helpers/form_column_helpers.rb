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
          send(method, column, options)
        # fallback: we get to make the decision
        else
          if column.association
            if column.form_ui.nil?
              # its an association and nothing is specified, we will assume form_ui :select
              active_scaffold_input_select(column, options)
            else
              # if we get here, it's because the column has a form_ui but not one ActiveScaffold knows about.
              raise "Unknown form_ui `#{column.form_ui}' for column `#{column.name}'"
            end
          elsif column.virtual?
            options[:value] = format_number_value(record.send(column.name), column.options) if column.number?
            active_scaffold_input_virtual(column, options)

          else # regular model attribute column
            # if we (or someone else) have created a custom render option for the column type, use that
            if (method = override_input(column.column.type))
              send(method, column, options)
            # final ultimate fallback: use rails' generic input method
            else
              # for textual fields we pass different options
              text_types = %i[text string integer float decimal date time datetime]
              options = active_scaffold_input_text_options(options) if text_types.include?(column.column.type)
              if column.column.type == :string && options[:maxlength].blank?
                options[:maxlength] = column.column.limit
                options[:size] ||= options[:maxlength].to_i > 30 ? 30 : options[:maxlength]
              end
              options[:include_blank] = true if column.column.null && %i[date datetime time].include?(column.column.type)
              options[:value] = format_number_value(record.send(column.name), column.options) if column.number?
              text_field(:record, column.name, options.merge(column.options).except(:format))
            end
          end
        end
      rescue StandardError => e
        logger.error "#{e.class.name}: #{e.message} -- on the ActiveScaffold column = :#{column.name} in #{controller.class}"
        raise e
      end

      def active_scaffold_render_subform_column(column, scope, crud_type, readonly, add_class = false, record = nil)
        if add_class
          col_class = []
          col_class << 'required' if column.required?
          col_class << column.css_class unless column.css_class.nil? || column.css_class.is_a?(Proc)
          col_class << 'hidden' if column_renders_as(column) == :hidden
          col_class << 'checkbox' if column.form_ui == :checkbox
          col_class = col_class.join(' ')
        end
        if readonly && !record.new_record? || !record.authorized_for?(:crud_type => crud_type, :column => column.name)
          options = active_scaffold_input_options(column, scope).except(:name)
          options[:class] = "#{options[:class]} #{col_class}" if col_class
          content_tag :span, get_column_value(record, column), options
        else
          renders_as = column_renders_as(column)
          html = render_column(column, record, renders_as, scope, false, col_class)
          html = content_tag(:div, html, active_scaffold_subform_attributes(column)) if renders_as == :subform
          html
        end
      end

      def active_scaffold_subform_attributes(column, column_css_class = nil)
        {
          :class => "sub-form #{active_scaffold_config_for(column.association.klass).subform.layout}-sub-form #{column_css_class} #{column.name}-sub-form",
          :id => sub_form_id(:association => column.name)
        }
      end

      # the standard active scaffold options used for textual inputs
      def active_scaffold_input_text_options(options = {})
        options[:autocomplete] = 'off'
        options[:class] = "#{options[:class]} text-input".strip
        options
      end

      # the standard active scaffold options used for class, name and scope
      def active_scaffold_input_options(column, scope = nil, options = {})
        name = scope ? "record#{scope}[#{column.name}]" : "record[#{column.name}]"
        record = options[:object]

        # Add some HTML5 attributes for in-browser validation and better user experience
        if column.required? && (!@disable_required_for_new || scope.nil? || record.try(:persisted?))
          options[:required] = true
        end
        options[:placeholder] = column.placeholder if column.placeholder.present?

        # Fix for keeping unique IDs in subform
        id_control = "record_#{column.name}_#{[params[:eid], params[:parent_id] || params[:id]].compact.join '_'}"
        id_control += scope_id(scope) if scope

        classes = "#{column.name}-input"
        classes += ' numeric-input' if column.number?

        {:name => name, :class => classes, :id => id_control}.merge(options)
      end

      def current_form_columns(record, scope, subform_controller = nil)
        if scope
          subform_controller.active_scaffold_config.subform.columns.names
        elsif %i[new create edit update render_field].include? action_name.to_sym
          # disable update_columns for inplace_edit (GET render_field)
          return if action_name == 'render_field' && request.get?
          active_scaffold_config.send(record.new_record? ? :create : :update).columns.names
        end
      end

      def update_columns_options(column, scope, options, force = false)
        record = options[:object]
        subform_controller = controller.class.active_scaffold_controller_for(record.class) if scope
        form_columns = @main_columns.try(:names) if scope.nil? || subform_controller == controller.class
        form_columns ||= current_form_columns(record, scope, subform_controller)
        if force || (form_columns && column.update_columns && (column.update_columns & form_columns).present?)
          url_params = params_for(:action => 'render_field', :column => column.name, :id => record.to_param)
          if nested? && scope
            url_params[:nested] = url_params.slice(:parent_scaffold, :association, nested.param_name)
            url_params = url_params.except(:parent_scaffold, :association, nested.param_name)
          end
          if scope
            url_params[:parent_controller] ||= url_params[:controller].gsub(/^\//, '')
            url_params[:controller] = subform_controller.controller_path
            url_params[:scope] = scope
            url_params[:parent_id] = params[:parent_id] || params[:id]
          end

          options[:class] = "#{options[:class]} update_form".strip
          options['data-update_url'] = url_for(url_params)
          options['data-update_send_form'] = column.send_form_on_update_column
          options['data-update_send_form_selector'] = column.options[:send_form_selector] if column.options[:send_form_selector]
        end
        options
      end

      def field_attributes(column, record)
        {}
      end

      def render_column(column, record, renders_as, scope = nil, only_value = false, col_class = nil)
        if partial = override_form_field_partial(column)
          render :partial => partial, :locals => {:column => column, :only_value => only_value, :scope => scope, :col_class => col_class, :record => record}
        elsif renders_as == :field || override_form_field?(column)
          form_attribute(column, record, scope, only_value, col_class)
        elsif renders_as == :subform
          render :partial => 'form_association', :locals => {:column => column, :scope => scope, :parent_record => record}
        else
          form_hidden_attribute(column, record, scope)
        end
      end

      def form_attribute(column, record, scope = nil, only_value = false, col_class = nil)
        column_options = active_scaffold_input_options(column, scope, :object => record)
        attributes = field_attributes(column, record)
        attributes[:class] = "#{attributes[:class]} #{col_class}" if col_class.present?
        if only_value
          field = content_tag(:span, get_column_value(record, column), column_options.except(:name, :object))
          if column.association.nil? || column.association.belongs_to?
            # hidden field probably not needed, but leaving it just in case
            # but it isn't working for assocations which are not belongs_to
            method = column.association ? column.association.foreign_key : column.name
            field << hidden_field(:record, method, column_options)
          end
        else
          field = active_scaffold_input_for column, scope, column_options
        end

        content_tag :dl, attributes do
          %(<dt>#{label_tag label_for(column, column_options), column.label}</dt><dd>#{field}
#{loading_indicator_tag(:action => :render_field, :id => params[:id]) if column.update_columns}
#{content_tag :span, column.description, :class => 'description' if column.description.present?}
</dd>).html_safe
        end
      end

      def label_for(column, options)
        options[:id] unless column.form_ui == :select && column.association.try(:collection?)
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
        if column.association.try(:collection?)
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
        column.allow_add_existing && options_for_association_count(column.association, record) > 0
      end

      def column_show_add_new(column, associated, record)
        assoc = column.association
        value = assoc.singular?
        value ||= assoc.collection? && !assoc.readonly? && (!assoc.through? || !assoc.through_reflection.collection?)
        value &&= false unless assoc.klass.authorized_for?(:crud_type => :create)
        value
      end

      ##
      ## Form input methods
      ##

      def active_scaffold_grouped_options(column, select_options, optgroup)
        group_column = active_scaffold_config_for(column.association.klass).columns[optgroup]
        group_label = group_column.options[:label_method] if group_column
        group_label ||= group_column.try(:association) ? :to_label : :to_s
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
        if options[:multiple] && !options[:name].to_s.ends_with?('[]')
          options[:name] = "#{options[:name]}[]"
        end
      end

      def active_scaffold_input_singular_association(column, html_options, options = {})
        record = html_options.delete(:object)
        associated = record.send(column.association.name)

        select_options = sorted_association_options_find(column.association, nil, record)
        select_options.unshift(associated) unless associated.nil? || select_options.include?(associated)

        method = column.name
        options.merge! :selected => associated.try(:id), :include_blank => as_(:_select_), :object => record

        html_options.merge!(column.options[:html_options] || {})
        options.merge!(column.options)
        active_scaffold_select_name_with_multiple html_options
        active_scaffold_translate_select_options(options)

        html =
          if (optgroup = options.delete(:optgroup))
            select(:record, method, active_scaffold_grouped_options(column, select_options, optgroup), options, html_options)
          else
            collection_select(:record, method, select_options, :id, column.options[:label_method] || :to_label, options, html_options)
          end
        html << active_scaffold_refresh_link(column, html_options, record) if column.options[:refresh_link]
        html
      end

      def active_scaffold_file_with_remove_link(column, options, content, remove_file_prefix, controls_class)
        options = active_scaffold_input_text_options(options.merge(column.options))
        if content
          active_scaffold_file_with_content(column, content, options, remove_file_prefix, controls_class)
        else
          file_field(:record, column.name, options)
        end
      end

      def active_scaffold_file_with_content(column, content, options, remove_file_prefix, controls_class)
        required = options.delete(:required)
        case ActiveScaffold.js_framework
        when :jquery
          js_remove_file_code = "jQuery(this).prev().val('true'); jQuery(this).parent().hide().next().show()#{".find('input').attr('required', 'required')" if required}; return false;"
          js_dont_remove_file_code = "jQuery(this).parents('div.#{controls_class}').find('input.remove_file').val('false'); return false;"
        when :prototype
          js_remove_file_code = "$(this).previous().value='true'; $(this).up().hide().next().show()#{".down().writeAttribute('required', 'required')" if required}; return false;"
          js_dont_remove_file_code = "jQuery(this).parents('div.#{controls_class}').find('input.remove_file').val('false'); return false;"
        end

        object_name, method = options[:name].split(/\[(#{column.name})\]/)
        method.sub!(/#{column.name}/, "#{remove_file_prefix}\\0")
        fields = block_given? ? yield : ''
        input = file_field(:record, column.name, options.merge(:onchange => js_dont_remove_file_code))
        content_tag(:div, class: controls_class) do
          content_tag(:div) do
            content << ' | ' << fields <<
              hidden_field(object_name, method, :value => 'false', class: 'remove_file') <<
              content_tag(:a, as_(:remove_file), :href => '#', :onclick => js_remove_file_code)
          end << content_tag(:div, input, :style => 'display: none')
        end
      end

      def active_scaffold_refresh_link(column, html_options, record)
        link_options = {:object => record}
        if html_options['data-update_url']
          link_options['data-update_send_form'] = html_options['data-update_send_form']
          link_options['data-update_send_form_selector'] = html_options['data-update_send_form_selector']
        else
          scope = html_options[:name].scan(/^record((\[[^\]]*\])*)\[#{column.name}\]/)[0].try(:first) if html_options[:name]
          link_options = update_columns_options(column, scope.presence, link_options, true)
        end
        link_options[:class] = 'refresh-link'
        link_to(as_(:refresh), link_options.delete('data-update_url') || html_options['data-update_url'], link_options)
      end

      def active_scaffold_plural_association_options(column, record = nil)
        associated_options = record.send(column.association.name)
        [associated_options, associated_options | sorted_association_options_find(column.association, nil, record)]
      end

      def active_scaffold_input_plural_association(column, options)
        record = options.delete(:object)
        associated_options, select_options = active_scaffold_plural_association_options(column, record)

        html =
          if select_options.empty?
            content_tag(:span, as_(:no_options), :class => "#{options[:class]} no-options", :id => options[:id])
          else
            active_scaffold_checkbox_list(column, select_options, associated_options.collect(&:id), options)
          end
        html << active_scaffold_refresh_link(column, options, record) if column.options[:refresh_link]
        html
      end

      def active_scaffold_checkbox_option(option, label_method, associated_ids, checkbox_options, li_options = {})
        content_tag(:li, li_options) do
          option_id = option.is_a?(Array) ? option[1] : option.id
          label = option.is_a?(Array) ? option[0] : option.send(label_method)
          check_box_tag(checkbox_options[:name], option_id, associated_ids.include?(option_id), checkbox_options) <<
            content_tag(:label, label, :for => checkbox_options[:id])
        end
      end

      def active_scaffold_checkbox_list(column, select_options, associated_ids, options)
        label_method = column.options[:label_method] || :to_label
        html = hidden_field_tag("#{options[:name]}[]", '', :id => nil)
        html << content_tag(:ul, options.merge(:class => "#{options[:class]} checkbox-list#{' draggable-lists' if column.options[:draggable_lists]}")) do
          content = ''.html_safe
          select_options.each_with_index do |option, i|
            content << active_scaffold_checkbox_option(option, label_method, associated_ids, :name => "#{options[:name]}[]", :id => "#{options[:id]}_#{i}_id")
          end
          content
        end
        html
      end

      def active_scaffold_translated_option(column, text, value = nil)
        value = text if value.nil?
        [(text.is_a?(Symbol) ? column.active_record_class.human_attribute_name(text) : text), value]
      end

      def active_scaffold_enum_options(column, record = nil)
        column.options[:options]
      end

      def active_scaffold_input_enum(column, html_options, options = {})
        record = html_options.delete(:object)
        options[:selected] = record.send(column.name)
        options[:object] = record
        options_for_select = active_scaffold_enum_options(column, record).collect do |text, value|
          active_scaffold_translated_option(column, text, value)
        end
        html_options.merge!(column.options[:html_options] || {})
        options.merge!(column.options)
        active_scaffold_select_name_with_multiple html_options
        active_scaffold_translate_select_options(options)
        select(:record, column.name, options_for_select, options, html_options)
      end

      def active_scaffold_input_select(column, html_options)
        if column.association.try :singular?
          active_scaffold_input_singular_association(column, html_options)
        elsif column.association.try :collection?
          active_scaffold_input_plural_association(column, html_options)
        else
          active_scaffold_input_enum(column, html_options)
        end
      end

      def active_scaffold_radio_option(option, selected, column, radio_options)
        if column.association
          label_method = column.options[:label_method] || :to_label
          text, value = [option.send(label_method), option.id]
          checked = {:checked => selected == value}
        else
          text, value = active_scaffold_translated_option(column, *option)
        end

        id_key = radio_options[:"data-id"] ? :"data-id" : :id
        radio_options = radio_options.merge(id_key => radio_options[id_key] + '-' + value.to_s.parameterize)
        radio_options.merge!(checked) if checked
        content_tag(:label, radio_button(:record, column.name, value, radio_options) + text)
      end

      def active_scaffold_input_radio(column, html_options)
        record = html_options[:object]
        html_options.merge!(column.options[:html_options] || {})
        options =
          if column.association
            sorted_association_options_find(column.association, nil, record)
          else
            active_scaffold_enum_options(column, record)
          end

        selected = record.send(column.association.name).try(:id) if column.association
        radios = options.map do |option|
          active_scaffold_radio_option(option, selected, column, html_options)
        end
        safe_join radios
      end

      def active_scaffold_input_checkbox(column, options)
        check_box(:record, column.name, options.merge(column.options))
      end

      def active_scaffold_input_password(column, options)
        active_scaffold_text_input :password_field, column, options
      end

      def active_scaffold_input_textarea(column, options)
        text_area(:record, column.name, options.merge(:cols => column.options[:cols], :rows => column.options[:rows], :size => column.options[:size]))
      end

      def active_scaffold_input_virtual(column, options)
        active_scaffold_text_input :text_field, column, options
      end

      # Some fields from HTML5 (primarily for using in-browser validation)
      # Sadly, many of them lacks browser support

      # A text box, that accepts only valid email address (in-browser validation)
      def active_scaffold_input_email(column, options)
        active_scaffold_text_input :email_field, column, options
      end

      # A text box, that accepts only valid URI (in-browser validation)
      def active_scaffold_input_url(column, options)
        active_scaffold_text_input :url_field, column, options
      end

      # A text box, that accepts only valid phone-number (in-browser validation)
      def active_scaffold_input_telephone(column, options)
        active_scaffold_text_input :telephone_field, column, options, :format
      end

      # A spinbox control for number values (in-browser validation)
      def active_scaffold_input_number(column, options)
        active_scaffold_number_input :number_field, column, options, :format
      end

      # A slider control for number values (in-browser validation)
      def active_scaffold_input_range(column, options)
        active_scaffold_number_input :range_field, column, options, :format
      end

      # A slider control for number values (in-browser validation)
      def active_scaffold_number_input(method, column, options, remove_options = nil)
        options = numerical_constraints_for_column(column, options)
        active_scaffold_text_input method, column, options, remove_options
      end

      def active_scaffold_text_input(method, column, options, remove_options = nil)
        options = active_scaffold_input_text_options(options)
        options = options.merge(column.options)
        options = options.except(*remove_options) if remove_options.present?
        send method, :record, column.name, options
      end

      # A color picker
      def active_scaffold_input_color(column, options)
        options = active_scaffold_input_text_options(options)
        if column.column.try(:null)
          no_color = options[:object].send(column.name).nil?
          method = no_color ? :hidden_field : :color_field
          html = content_tag(:label, check_box_tag('disable', '1', no_color, id: nil, name: nil, class: 'no-color') << " #{as_ column.options[:no_color] || :no_color}")
        else
          method = :color_field
          html = ''.html_safe
        end
        html << send(method, :record, column.name, options.merge(column.options).except(:format, :no_color))
      end

      #
      # Column.type-based inputs
      #

      def active_scaffold_input_boolean(column, options)
        record = options.delete(:object)
        select_options = []
        select_options << [as_(:_select_), nil] if !column.virtual? && column.column.null
        select_options << [as_(:true), true]
        select_options << [as_(:false), false]

        select_tag(options[:name], options_for_select(select_options, record.send(column.name)), options)
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

      def subform_partial_for_column(column)
        subform_partial = "#{active_scaffold_config_for(column.association.klass).subform.layout}_subform"
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
        elsif column.association.nil? || column.form_ui || !active_scaffold_config_for(column.association.klass).actions.include?(:subform) || override_form_field?(column)
          :field
        else
          :subform
        end
      end

      def column_scope(column, scope = nil, record = nil)
        if column.association.try(:collection?)
          "#{scope}[#{column.name}][#{record.id || generate_temporary_id(record)}]"
        else
          "#{scope}[#{column.name}]"
        end
      end

      def active_scaffold_add_existing_input(options)
        record = options.delete(:object)
        if !ActiveScaffold.js_framework.nil? && controller.respond_to?(:record_select_config, true)
          remote_controller = active_scaffold_controller_for(record_select_config.model).controller_path
          options[:controller] = remote_controller
          options.merge!(active_scaffold_input_text_options)
          record_select_field(options[:name], record, options)
        else
          select_options = sorted_association_options_find(nested.association, nil, record)
          select_options ||= active_scaffold_config.model.all
          select_options = options_from_collection_for_select(select_options, :id, :to_label)
          select_tag 'associated_id', ('<option value="">' + as_(:_select_) + '</option>' + select_options).html_safe unless select_options.empty?
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
      def numerical_constraints_for_column(column, options)
        if column.numerical_constraints.nil?
          numerical_constraints = {}
          validators = column.active_record_class.validators.select do |v|
            v.is_a?(ActiveModel::Validations::NumericalityValidator) && v.attributes.include?(column.name)
          end
          equal_to = (val = validators.find { |v| v.options[:equal_to] }) ? val.options[:equal_to] : nil

          # If there is equal_to constraint - use it (unless otherwise specified by user)
          if equal_to && !(options[:min] || options[:max])
            numerical_constraints[:min] = numerical_constraints[:max] = equal_to
          else # find minimum and maximum from validators
            # we can safely modify :min and :max by 1 for :greater_tnan or :less_than value only for integer values
            only_integer = column.column.type == :integer if column.column
            only_integer ||= validators.find { |v| v.options[:only_integer] }.present?
            margin = only_integer ? 1 : 0

            # Minimum
            unless options[:min]
              min = validators.map { |v| v.options[:greater_than_or_equal] }.compact.max
              greater_than = validators.map { |v| v.options[:greater_than] }.compact.max
              numerical_constraints[:min] = [min, (greater_than + margin if greater_than)].compact.max
            end

            # Maximum
            unless options[:max]
              max = validators.map { |v| v.options[:less_than_or_equal] }.compact.min
              less_than = validators.map { |v| v.options[:less_than] }.compact.min
              numerical_constraints[:max] = [max, (less_than - margin if less_than)].compact.min
            end

            # Set step = 2 for column values restricted to be odd or even (but only if minimum is set)
            unless options[:step]
              only_odd_valid  = validators.any? { |v| v.options[:odd] }
              only_even_valid = validators.any? { |v| v.options[:even] } unless only_odd_valid
              if !only_integer
                numerical_constraints[:step] ||= "0.#{'0' * (column.column.scale - 1)}1" if column.column && column.column.scale.to_i > 0
              elsif options[:min] && options[:min].respond_to?(:even?) && (only_odd_valid || only_even_valid)
                numerical_constraints[:step] = 2
                numerical_constraints[:min] += 1 if only_odd_valid  && options[:min].even?
                numerical_constraints[:min] += 1 if only_even_valid && options[:min].odd?
              end
              numerical_constraints[:step] ||= 'any' unless only_integer
            end
          end

          column.numerical_constraints = numerical_constraints
        end
        column.numerical_constraints.merge(options)
      end
    end
  end
end
