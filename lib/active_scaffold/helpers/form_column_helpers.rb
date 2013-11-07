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
        ActiveSupport::Deprecation.warn "Relying on @record is deprecated, include :object in options with record.", caller if record.nil? # TODO Remove when relying on @record is removed
        record ||= @record # TODO Remove when relying on @record is removed
        begin
          # first, check if the dev has created an override for this specific field
          if (method = override_form_field(column))
            send(method, record, options)
          # second, check if the dev has specified a valid form_ui for this column
          elsif column.form_ui and (method = override_input(column.form_ui))
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
                text_types = [:text, :string, :integer, :float, :decimal, :date, :time, :datetime]
                options = active_scaffold_input_text_options(options) if text_types.include?(column.column.type)
                if column.column.type == :string && options[:maxlength].blank?
                  options[:maxlength] = column.column.limit
                  options[:size] ||= options[:maxlength].to_i > 30 ? 30 : options[:maxlength]
                end
                options[:include_blank] = true if column.column.null and [:date, :datetime, :time].include?(column.column.type)
                options[:value] = format_number_value(record.send(column.name), column.options) if column.number?
                text_field(:record, column.name, options.merge(column.options))
              end
            end
          end
        rescue Exception => e
          logger.error "#{e.class.name}: #{e.message} -- on the ActiveScaffold column = :#{column.name} in #{controller.class}"
          raise e
        end
      end
      
      def active_scaffold_render_subform_column(column, scope, crud_type, readonly, add_class = false, record = nil)
        ActiveSupport::Deprecation.warn "Relying on @record is deprecated, call with record.", caller if record.nil? # TODO Remove when relying on @record is removed
        record ||= @record # TODO Remove when relying on @record is removed
        if add_class
          col_class = []
          col_class << 'required' if column.required?
          col_class << column.css_class unless column.css_class.nil? || column.css_class.is_a?(Proc)
          col_class << 'hidden' if column_renders_as(column) == :hidden
          col_class << 'checkbox' if column.form_ui == :checkbox
          col_class = col_class.join(' ')
        end
        unless readonly and not record.new_record? or not record.authorized_for?(:crud_type => crud_type, :column => column.name)
          render_column(column, record, column_renders_as(column), scope, false, col_class)
        else
          options = active_scaffold_input_options(column, scope).except(:name)
          options[:class] = "#{options[:class]} #{col_class}" if col_class
          content_tag :span, get_column_value(record, column), options
        end
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

        { :name => name, :class => classes, :id => id_control}.merge(options)
      end

      def update_columns_options(column, scope, options)
        record = options[:object]
        ActiveSupport::Deprecation.warn "Relying on @record is deprecated, include :object in options with record.", caller if record.nil? # TODO Remove when relying on @record is removed
        record ||= @record # TODO Remove when relying on @record is removed
        form_action = if scope
          subform_controller = controller.class.active_scaffold_controller_for(record.class)
          subform_controller.active_scaffold_config.subform
        elsif [:new, :create, :edit, :update, :render_field].include? params[:action].to_sym
          active_scaffold_config.send(record.new_record? ? :create : :update)
        end
        if form_action && column.update_columns && (column.update_columns & form_action.columns.names).present?
          url_params = params_for(:action => 'render_field', :column => column.name, :id => record.to_param)
          url_params = url_params.except(:parent_scaffold, :association, nested.param_name) if nested? && scope
          url_params[:eid] = params[:eid] if params[:eid]
          if scope
            url_params[:parent_controller] ||= url_params[:controller]
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
        if override_form_field_partial?(column)
          render :partial => override_form_field_partial(column), :locals => { :column => column, :only_value => only_value, :scope => scope, :col_class => col_class, :record => record }
        elsif renders_as == :field || override_form_field?(column)
          form_attribute(column, record, scope, only_value, col_class)
        elsif renders_as == :subform
          render :partial => 'form_association', :locals => { :column => column, :scope => scope, :parent_record => record }
        else
          form_hidden_attribute(column, record, scope)
        end
      end
      
      def form_attribute(column, record, scope = nil, only_value = false, col_class = nil)
        column_options = active_scaffold_input_options(column, scope, :object => record)
        attributes = field_attributes(column, record)
        attributes[:class] = "#{attributes[:class]} #{col_class}" if col_class.present?
        field = unless only_value
          active_scaffold_input_for column, scope, column_options
        else
          content_tag(:span, get_column_value(record, column), column_options.except(:name, :object)) <<
          hidden_field(:record, column.association ? column.association.foreign_key : column.name, column_options)
        end
        
        content_tag :dl, attributes do
          %|<dt>#{label_tag label_for(column, column_options), column.label}</dt><dd>#{field}
#{loading_indicator_tag(:action => :render_field, :id => params[:id]) if column.update_columns}
#{content_tag :span, column.description, :class => 'description' if column.description.present?}
</dd>|.html_safe
        end
      end

      def label_for(column, options)
        options[:id] unless column.form_ui == :select && column.plural_association?
      end

      def subform_label(column, hidden)
        column.label unless hidden
      end
      
      def form_hidden_attribute(column, record, scope = nil)
        %|<dl style="display: none;"><dt></dt><dd>
#{hidden_field :record, column.name, active_scaffold_input_options(column, scope).merge(:object => record)}
</dd></dl>|.html_safe
      end

      # Should this column be displayed in the subform?
      def in_subform?(column, parent_record)
        return true unless column.association

        # Polymorphic associations can't appear because they *might* be the reverse association, and because you generally don't assign an association from the polymorphic side ... I think.
        return false if column.polymorphic_association?

        # A column shouldn't be in the subform if it's the reverse association to the parent
        return false if column.association.inverse_for?(parent_record.class)

        return true
      end

      def column_show_add_existing(column, record = nil)
        ActiveSupport::Deprecation.warn "Relying on @record is deprecated, call with record.", caller if record.nil? # TODO Remove when relying on @record is removed
        record ||= @record # TODO Remove when relying on @record is removed
        (column.allow_add_existing and options_for_association_count(column.association, record) > 0)
      end

      def column_show_add_new(column, associated, record)
        value = (column.plural_association? && !column.readonly_association?) || column.singular_association?
        value &&= false unless column.association.klass.authorized_for?(:crud_type => :create)
        value
      end

      ##
      ## Form input methods
      ##
      
      def active_scaffold_grouped_options(column, select_options, optgroup)
        group_label = active_scaffold_config_for(column.association.klass).columns[optgroup].try(:association) ? :to_label : :to_s
        select_options.group_by(&optgroup.to_sym).collect do |group, options|
          [group.send(group_label), options.collect {|r| [r.to_label, r.id]}]
        end
      end

      def active_scaffold_translate_select_options(options)
        options[:include_blank] = as_(options[:include_blank].to_s) if options[:include_blank].is_a? Symbol
        options[:prompt] = as_(options[:prompt].to_s) if options[:prompt].is_a? Symbol
        options
      end
      
      def active_scaffold_input_singular_association(column, html_options)
        record = html_options.delete(:object)
        ActiveSupport::Deprecation.warn "Relying on @record is deprecated, include :object in html_options with record.", caller if record.nil? # TODO Remove when relying on @record is removed
        record ||= @record # TODO Remove when relying on @record is removed
        associated = record.send(column.association.name)

        select_options = sorted_association_options_find(column.association, nil, record)
        select_options.unshift(associated) unless associated.nil? || select_options.include?(associated)

        method = column.name
        options = {:selected => associated.try(:id), :include_blank => as_(:_select_), :object => record}

        html_options.merge!(column.options[:html_options] || {})
        options.merge!(column.options)
        html_options[:name] = "#{html_options[:name]}[]" if html_options[:multiple] == true && !html_options[:name].to_s.ends_with?("[]")
        active_scaffold_translate_select_options(options)

        if optgroup = options.delete(:optgroup)
          select(:record, method, active_scaffold_grouped_options(column, select_options, optgroup), options, html_options)
        else
          collection_select(:record, method, select_options, :id, :to_label, options, html_options)
        end
      end

      def active_scaffold_plural_association_options(column, record = nil)
        ActiveSupport::Deprecation.warn "Relying on @record is deprecated, call with record.", caller if record.nil? # TODO Remove when relying on @record is removed
        record ||= @record # TODO Remove when relying on @record is removed
        associated_options = record.send(column.association.name)
        [associated_options, associated_options | sorted_association_options_find(column.association, nil, record)]
      end

      def active_scaffold_input_plural_association(column, options)
        record = options.delete(:object)
        ActiveSupport::Deprecation.warn "Relying on @record is deprecated, include :object in options with record.", caller if record.nil? # TODO Remove when relying on @record is removed
        record ||= @record # TODO Remove when relying on @record is removed
        associated_options, select_options = active_scaffold_plural_association_options(column, record)
        return content_tag(:span, as_(:no_options), :class => options[:class], :id => options[:id]) if select_options.empty?

        active_scaffold_checkbox_list(column, select_options.collect {|r| [r.to_label, r.id]}, associated_options.collect(&:id), options)
      end
      
      def active_scaffold_checkbox_list(column, select_options, associated_ids, options)
        html = hidden_field_tag("#{options[:name]}[]", '', :id => nil)
        html << content_tag(:ul, :class => "#{options[:class]} checkbox-list#{' draggable-lists' if column.options[:draggable_lists]}", :id => options[:id]) do
          content = ''.html_safe
          select_options.each_with_index do |option, i|
            label, id = option
            this_id = "#{options[:id]}_#{i}_id"
            content << content_tag(:li) do 
              check_box_tag("#{options[:name]}[]", id, associated_ids.include?(id), :id => this_id) <<
              content_tag(:label, h(label), :for => this_id)
            end
          end
          content
        end
        html << javascript_tag("ActiveScaffold.draggable_lists('#{options[:id]}')") if column.options[:draggable_lists] && ActiveScaffold.js_framework == :prototype
        html
      end

      def active_scaffold_translated_option(column, text, value = nil)
        value = text if value.nil?
        [(text.is_a?(Symbol) ? column.active_record_class.human_attribute_name(text) : text), value]
      end
      
      def active_scaffold_enum_options(column)
        column.options[:options]
      end

      def active_scaffold_input_enum(column, html_options)
        record = html_options.delete(:object)
        ActiveSupport::Deprecation.warn "Relying on @record is deprecated, include :object in html_options with record.", caller if record.nil? # TODO Remove when relying on @record is removed
        record ||= @record # TODO Remove when relying on @record is removed
        options = { :selected => record.send(column.name), :object => record }
        options_for_select = active_scaffold_enum_options(column).collect do |text, value|
          active_scaffold_translated_option(column, text, value)
        end
        html_options.merge!(column.options[:html_options] || {})
        options.merge!(column.options)
        active_scaffold_translate_select_options(options)
        select(:record, column.name, options_for_select, options, html_options)
      end

      def active_scaffold_input_select(column, html_options)
        if column.singular_association?
          active_scaffold_input_singular_association(column, html_options)
        elsif column.plural_association?
          active_scaffold_input_plural_association(column, html_options)
        else
          active_scaffold_input_enum(column, html_options)
        end
      end

      def active_scaffold_input_radio(column, html_options)
        html_options.merge!(column.options[:html_options] || {})
        column.options[:options].inject('') do |html, (text, value)|
          text, value = active_scaffold_translated_option(column, text, value)
          html << content_tag(:label, radio_button(:record, column.name, value, html_options.merge(:id => html_options[:id] + '-' + value.to_s)) + text)
        end.html_safe
      end

      def active_scaffold_input_checkbox(column, options)
        check_box(:record, column.name, options.merge(column.options))
      end

      def active_scaffold_input_password(column, options)
        options = active_scaffold_input_text_options(options)
        password_field :record, column.name, options.merge(column.options)
      end

      def active_scaffold_input_textarea(column, options)
        text_area(:record, column.name, options.merge(:cols => column.options[:cols], :rows => column.options[:rows], :size => column.options[:size]))
      end
      
      def active_scaffold_input_virtual(column, options)
        options = active_scaffold_input_text_options(options)
        text_field :record, column.name, options.merge(column.options)
      end

      # Some fields from HTML5 (primarily for using in-browser validation)
      # Sadly, many of them lacks browser support

      # A text box, that accepts only valid email address (in-browser validation)
      def active_scaffold_input_email(column, options)
        options = active_scaffold_input_text_options(options)
        email_field :record, column.name, options.merge(column.options)
      end

      # A text box, that accepts only valid URI (in-browser validation)
      def active_scaffold_input_url(column, options)
        options = active_scaffold_input_text_options(options)
        url_field :record, column.name, options.merge(column.options)
      end

      # A text box, that accepts only valid phone-number (in-browser validation)
      def active_scaffold_input_telephone(column, options)
        options = active_scaffold_input_text_options(options)
        telephone_field :record, column.name, options.merge(column.options)
      end

      # A spinbox control for number values (in-browser validation)
      def active_scaffold_input_number(column, options)
        options = numerical_constraints_for_column(column, options)
        options = active_scaffold_input_text_options(options)
        number_field :record, column.name, options.merge(column.options)
      end

      # A slider control for number values (in-browser validation)
      def active_scaffold_input_range(column, options)
        options = numerical_constraints_for_column(column, options)
        options = active_scaffold_input_text_options(options)
        range_field :record, column.name, options.merge(column.options)
      end

      #
      # Column.type-based inputs
      #

      def active_scaffold_input_boolean(column, options)
        record = options.delete(:object)
        ActiveSupport::Deprecation.warn "Relying on @record is deprecated, include :object in options with record.", caller if record.nil? # TODO Remove when relying on @record is removed
        record ||= @record # TODO Remove when relying on @record is removed
        select_options = []
        select_options << [as_(:_select_), nil] if !column.virtual? && column.column.null
        select_options << [as_(:true), true]
        select_options << [as_(:false), false]

        select_tag(options[:name], options_for_select(select_options, record.send(column.name)), options)
      end

      def onsubmit
      end

      ##
      ## Form column override signatures
      ##

      # add functionality for overriding subform partials from association class path
      def override_subform_partial?(column, subform_partial)
        template_exists?(override_subform_partial(column, subform_partial), true)
      end

      def override_subform_partial(column, subform_partial)
        File.join(active_scaffold_controller_for(column.association.klass).controller_path, subform_partial) if column_renders_as(column) == :subform
      end

      def override_form_field_partial?(column)
        template_exists?(override_form_field_partial(column), true)
      end

      # the naming convention for overriding form fields with helpers
      def override_form_field_partial(column)
        path = active_scaffold_controller_for(column.active_record_class).controller_path
        File.join(path, "#{clean_column_name(column.name)}_form_column")
      end

      def override_form_field(column)
        override_helper column, 'form_column'
      end
      alias_method :override_form_field?, :override_form_field

      # the naming convention for overriding form input types with helpers
      def override_input(form_ui)
        method = "active_scaffold_input_#{form_ui}"
        method if respond_to? method
      end
      alias_method :override_input?, :override_input

      def subform_partial_for_column(column)
        subform_partial = "#{active_scaffold_config_for(column.association.klass).subform.layout}_subform"
        if override_subform_partial?(column, subform_partial)
          override_subform_partial(column, subform_partial)
        else
          subform_partial
        end
      end

      ##
      ## Macro-level rendering decisions for columns
      ##

      def column_renders_as(column)
        if column.respond_to? :each
          return :subsection
        elsif column.active_record_class.locking_column.to_s == column.name.to_s or column.form_ui == :hidden
          return :hidden
        elsif column.association.nil? or column.form_ui or !active_scaffold_config_for(column.association.klass).actions.include?(:subform) or override_form_field?(column)
          return :field
        else
          return :subform
        end
      end

      def column_scope(column, scope = nil, record = nil)
        ActiveSupport::Deprecation.warn "Relying on @record is deprecated, call with record.", caller if record.nil? # TODO Remove when relying on @record is removed
        if column.plural_association?
          "#{scope}[#{column.name}][#{record.id || generate_temporary_id(record)}]"
        else
          "#{scope}[#{column.name}]"
        end
      end

      def active_scaffold_add_existing_input(options)
        record = options.delete(:object)
        ActiveSupport::Deprecation.warn "Relying on @record is deprecated, include :object in options with record.", caller if record.nil? # TODO Remove when relying on @record is removed
        record ||= @record # TODO Remove when relying on @record is removed
        if ActiveScaffold.js_framework == :prototype && controller.respond_to?(:record_select_config, true)
          remote_controller = active_scaffold_controller_for(record_select_config.model).controller_path
          options.merge!(:controller => remote_controller)
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
            v.is_a? ActiveModel::Validations::NumericalityValidator and v.attributes.include? column.name
          end
          equal_to = (v = validators.find{ |v| v.options[:equal_to] }) ? v.options[:equal_to] : nil
          
          # If there is equal_to constraint - use it (unless otherwise specified by user)
          if equal_to and not (options[:min] or options[:max])
            numerical_constraints[:min] = numerical_constraints[:max] = equal_to
          else # find minimum and maximum from validators
            # we can safely modify :min and :max by 1 for :greater_tnan or :less_than value only for integer values
            only_integer = column.column.type == :integer if column.column
            only_integer ||= !!validators.find{ |v| v.options[:only_integer] }
            margin = only_integer ? 1 : 0
            
            # Minimum
            unless options[:min]
              min = validators.map{ |v| v.options[:greater_than_or_equal] }.compact.max
              greater_than = validators.map{ |v| v.options[:greater_than] }.compact.max
              numerical_constraints[:min] = [min, (greater_than+margin if greater_than)].compact.max
            end
            
            # Maximum
            unless options[:max]
              max = validators.map{ |v| v.options[:less_than_or_equal] }.compact.min
              less_than = validators.map{ |v| v.options[:less_than] }.compact.min
              numerical_constraints[:max] = [max, (less_than-margin if less_than)].compact.min
            end
            
            # Set step = 2 for column values restricted to be odd or even (but only if minimum is set)
            unless options[:step]
              only_odd_valid  = validators.any?{ |v| v.options[:odd] }
              only_even_valid = validators.any?{ |v| v.options[:even] } unless only_odd_valid
              if !only_integer
                numerical_constraints[:step] ||= "0.#{'0'*(column.column.scale-1)}1" if column.column && column.column.scale.to_i > 0
              elsif options[:min] and options[:min].respond_to? :even? and (only_odd_valid or only_even_valid)
                numerical_constraints[:step] = 2
                numerical_constraints[:min] += 1 if only_odd_valid  and not options[:min].odd?
                numerical_constraints[:min] += 1 if only_even_valid and not options[:min].even?
              end
              numerical_constraints[:step] ||= 'any' unless only_integer
            end
          end
          
          column.numerical_constraints = numerical_constraints
        end
        return column.numerical_constraints.merge(options)
      end
    end
  end
end
