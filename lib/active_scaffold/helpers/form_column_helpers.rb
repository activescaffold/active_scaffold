module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumnHelpers
      # This method decides which input to use for the given column.
      # It does not do any rendering. It only decides which method is responsible for rendering.
      def active_scaffold_input_for(column, scope = nil, options = {})
        options = active_scaffold_input_options(column, scope, options)
        options = update_columns_options(column, scope, options)
        active_scaffold_render_input(column, options)
      end

      alias form_column active_scaffold_input_for

      def active_scaffold_render_input(column, options)
        begin
          # first, check if the dev has created an override for this specific field
          if (method = override_form_field(column))
            send(method, @record, options)
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
              options[:value] = format_number_value(@record.send(column.name), column.options) if column.number?
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
                  options[:size] ||= ActionView::Helpers::InstanceTag::DEFAULT_FIELD_OPTIONS["size"]
                end
                options[:include_blank] = true if column.column.null and [:date, :datetime, :time].include?(column.column.type)
                options[:value] = format_number_value(@record.send(column.name), column.options) if column.number?
                text_field(:record, column.name, options.merge(column.options))
              end
            end
          end
        rescue Exception => e
          logger.error Time.now.to_s + "#{e.inspect} -- on the ActiveScaffold column = :#{column.name} in #{controller.class}"
          raise e
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

        # Add some HTML5 attributes for in-browser validation and better user experience
        if column.required? && (!@disable_required_for_new || scope.nil? || @record.persisted?)
          options[:required] = true
        end
        options[:placeholder] = column.placeholder if column.placeholder.present?

        # Fix for keeping unique IDs in subform
        id_control = "record_#{column.name}_#{[params[:eid], params[:id]].compact.join '_'}"
        id_control += scope_id(scope) if scope
        
        classes = "#{column.name}-input"
        classes += ' numeric-input' if column.number?

        { :name => name, :class => classes, :id => id_control}.merge(options)
      end

      def update_columns_options(column, scope, options)
        if column.update_columns
          form_action = params[:action] == 'edit' ? :update : :create
          url_params = {:action => 'render_field', :id => params[:id], :column => column.name}
          url_params[:eid] = params[:eid] if params[:eid]
          url_params[:controller] = controller.class.active_scaffold_controller_for(@record.class).controller_path if scope
          url_params[:scope] = scope if scope

          options[:class] = "#{options[:class]} update_form".strip
          options['data-update_url'] = url_for(url_params)
          options['data-update_send_form'] = true if column.send_form_on_update_column
          options['data-update_send_form_selector'] = column.options[:send_form_selector] if column.options[:send_form_selector]
        end
        options
      end

      ##
      ## Form input methods
      ##

      def active_scaffold_input_singular_association(column, html_options)
        associated = @record.send(column.association.name)

        select_options = options_for_association(column.association)
        select_options.unshift([ associated.to_label, associated.id ]) unless associated.nil? or select_options.find {|label, id| id == associated.id}

        method = column.name
        #html_options[:name] += '[id]'
        options = {:selected => associated.try(:id), :include_blank => as_(:_select_)}

        html_options.update(column.options[:html_options] || {})
        options.update(column.options)
        html_options[:name] = "#{html_options[:name]}[]" if (html_options[:multiple] == true && !html_options[:name].to_s.ends_with?("[]"))
        select(:record, method, select_options.uniq, options, html_options)
      end

      def active_scaffold_input_plural_association(column, options)
        associated_options = @record.send(column.association.name).collect {|r| [r.to_label, r.id]}
        select_options = associated_options | options_for_association(column.association)
        return content_tag(:span, as_(:no_options), :class => options[:class], :id => options[:id]) if select_options.empty?

        active_scaffold_checkbox_list(column, select_options, associated_options.collect {|a| a[1]}, options)
      end
      
      def active_scaffold_checkbox_list(column, select_options, associated_ids, options)
        html = content_tag :ul, :class => "#{options[:class]} checkbox-list", :id => options[:id] do
          content = hidden_field_tag("#{options[:name]}[]", '')
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
        html << javascript_tag("ActiveScaffold.draggable_lists('#{options[:id]}')") if column.options[:draggable_lists]
        html
      end

      def active_scaffold_translated_option(column, text, value = nil)
        value = text if value.nil?
        [(text.is_a?(Symbol) ? column.active_record_class.human_attribute_name(text) : text), value]
      end

      def active_scaffold_input_enum(column, html_options)
        options = { :selected => @record.send(column.name) }
        options_for_select = column.options[:options].collect do |text, value|
          active_scaffold_translated_option(column, text, value)
        end
        html_options.update(column.options[:html_options] || {})
        options.update(column.options)
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
        html_options.update(column.options[:html_options] || {})
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
        select_options = []
        select_options << [as_(:_select_), nil] if !column.virtual? && column.column.null
        select_options << [as_(:true), true]
        select_options << [as_(:false), false]

        select_tag(options[:name], options_for_select(select_options, @record.send(column.name)), options)
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

      def form_partial_for_column(column, renders_as = nil)
        renders_as ||= column_renders_as(column)
        if override_form_field_partial?(column)
          override_form_field_partial(column)
        elsif renders_as == :field or override_form_field?(column)
          "form_attribute"
        elsif renders_as == :subform
          "form_association"
        elsif renders_as == :hidden
          "form_hidden_attribute"
        end
      end

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
        if column.is_a? ActiveScaffold::DataStructures::ActionColumns
          return :subsection
        elsif column.active_record_class.locking_column.to_s == column.name.to_s or column.form_ui == :hidden
          return :hidden
        elsif column.association.nil? or column.form_ui or !active_scaffold_config_for(column.association.klass).actions.include?(:subform)
          return :field
        else
          return :subform
        end
      end

      def column_scope(column, scope = nil)
        if column.plural_association?
          "#{scope}[#{column.name}][#{@record.id || generate_temporary_id}]"
        else
          "#{scope}[#{column.name}]"
        end
      end

      def active_scaffold_add_existing_input(options)
        if ActiveScaffold.js_framework == :prototype && controller.respond_to?(:record_select_config)
          remote_controller = active_scaffold_controller_for(record_select_config.model).controller_path
          options.merge!(:controller => remote_controller)
          options.merge!(active_scaffold_input_text_options)
          record_select_field(options[:name], @record, options)
        else
          select_options = options_for_select(options_for_association(nested.association)) #unless column.through_association?
          select_options ||= options_for_select(active_scaffold_config.model.all.collect {|c| [h(c.to_label), c.id]})
          select_tag 'associated_id', ('<option value="">' + as_(:_select_) + '</option>' + select_options).html_safe unless select_options.empty?
        end
      end

      def active_scaffold_add_existing_label
        if controller.respond_to?(:record_select_config)
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
          equal_to = validators.map{ |v| v.options[:equal_to] }.compact.first
          
          # If there is equal_to constraint - use it (unless otherwise specified by user)
          if equal_to and not (options[:min] or options[:max])
            numerical_constraints[:min] = numerical_constraints[:max] = equal_to
          else # find minimum and maximum from validators
            # we can safely modify :min and :max by 1 for :greater_tnan or :less_than value only for integer values
            only_integer = validators.map{ |v| v.options[:only_integer] }.compact.any?
            margin = only_integer ? 1 : 0
            
            # Minimum
            unless options[:min]
              min = validators.map{ |v| v.options[:greater_than_or_equal] }.compact.max
              greater_than = validators.map{ |v| v.options[:greater_than] }.compact.max
              numerical_constraints[:min] = [min, (greater_than.nil?? nil : greater_than+margin)].compact.max
            end
            
            # Maximum
            unless options[:max]
              max = validators.map{ |v| v.options[:less_than_or_equal] }.compact.min
              less_than = validators.map{ |v| v.options[:less_than] }.compact.min
              numerical_constraints[:max] = [max, (less_than.nil?? nil : less_than-margin)].compact.min
            end
            
            # Set step = 2 for column values restricted to be odd or even (but only if minimum is set)
            unless options[:step]
              only_odd_valid  = validators.map{ |v| v.options[:odd] }.compact.any?
              only_even_valid = validators.map{ |v| v.options[:even] }.compact.any?
              if options[:min] and options[:min].respond_to? :even? and (only_odd_valid or only_even_valid)
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
