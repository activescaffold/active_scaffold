module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumnHelpers
      # This method decides which input to use for the given column.
      # It does not do any rendering. It only decides which method is responsible for rendering.
      def active_scaffold_input_for(column, scope = nil, options = {})
        begin
          options = active_scaffold_input_options(column, scope, options)
          options = javascript_for_update_column(column, scope, options)
          # first, check if the dev has created an override for this specific field
          if override_form_field?(column)
            send(override_form_field(column), @record, options)
          # second, check if the dev has specified a valid form_ui for this column
          elsif column.form_ui and override_input?(column.form_ui)
            send(override_input(column.form_ui), column, options)
          # fallback: we get to make the decision
          else
            if column.association
              # if we get here, it's because the column has a form_ui but not one ActiveScaffold knows about.
              raise "Unknown form_ui `#{column.form_ui}' for column `#{column.name}'"
            elsif column.virtual?
              active_scaffold_input_virtual(column, options)

            else # regular model attribute column
              # if we (or someone else) have created a custom render option for the column type, use that
              if override_input?(column.column.type)
                send(override_input(column.column.type), column, options)
              # final ultimate fallback: use rails' generic input method
              else
                # for textual fields we pass different options
                text_types = [:text, :string, :integer, :float, :decimal]
                date_types = [:date, :datetime, :time]
                options = active_scaffold_input_text_options(options) if text_types.include?(column.column.type)
                options = active_scaffold_input_date_options(column, options) if date_types.include?(column.column.type)
                if column.column.type == :string && options[:maxlength].blank?
                  options[:maxlength] = column.column.limit
                  options[:size] ||= ActionView::Helpers::InstanceTag::DEFAULT_FIELD_OPTIONS["size"]
                end
                options[:value] = format_number_value(@record.send(column.name), column.options) if column.column.number?
                input(:record, column.name, options.merge(column.options))
              end
            end
          end
        rescue Exception => e
          logger.error Time.now.to_s + "#{e.inspect} -- on the ActiveScaffold column = :#{column.name} in #{@controller.class}"
          raise e
        end
      end

      alias form_column active_scaffold_input_for

      # the standard active scaffold options used for textual inputs
      def active_scaffold_input_text_options(options = {})
        options[:autocomplete] = 'off'
        options[:class] = "#{options[:class]} text-input".strip
        options
      end

      # the standard active scaffold options used for date, datetime and time inputs
      def active_scaffold_input_date_options(column, options = {})
        options[:include_blank] = true if column.column.null
        options[:prefix] = options[:name].gsub("[#{column.name}]", '')
        options
      end

      # the standard active scaffold options used for class, name and scope
      def active_scaffold_input_options(column, scope = nil, options = {})
        name = scope ? "record#{scope}[#{column.name}]" : "record[#{column.name}]"

        # Fix for keeping unique IDs in subform
        id_control = "record_#{column.name}_#{[params[:eid], params[:id]].compact.join '_'}"
        id_control += scope.gsub(/(\[|\])/, '_').gsub('__', '_').gsub(/_$/, '') if scope

        { :name => name, :class => "#{column.name}-input", :id => id_control}.merge(options)
      end

      def javascript_for_update_column(column, scope, options)
        if column.update_column
          form_action = :create
          form_action = :update if params[:action] == 'edit'
          url_params = {
            :action => 'render_field',
            :id => params[:id],
            :column => column.name,
            :update_column => column.update_column,
            :eid => params[:eid],
            :scope => scope
          }
          url_params[:controller] = controller.class.active_scaffold_controller_for(@record.class).controller_path if scope
          ajax_options = {:method => :get, 
                          :url => url_for(url_params), :with => column.send_form_on_update_column ? "Form.serialize('#{element_form_id(:action => form_action)}')" : "'value=' + this.value",
                          :after => "$('#{loading_indicator_id(:action => form_action, :id => params[:id])}').style.visibility = 'visible'; Form.disable('#{element_form_id(:action => form_action)}');",
                          :complete => "$('#{loading_indicator_id(:action => form_action, :id => params[:id])}').style.visibility = 'hidden'; Form.enable('#{element_form_id(:action => form_action)}');"}
          options[:onchange] = "#{remote_function(ajax_options)};#{options[:onchange]}"
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

        selected = associated.nil? ? nil : associated.id
        method = column.name
        #html_options[:name] += '[id]'
        options = {:selected => selected, :include_blank => as_(:_select_)}

        html_options.update(column.options[:html_options] || {})
        options.update(column.options)
        select(:record, method, select_options.uniq, options, html_options)
      end

      def active_scaffold_input_plural_association(column, options)
        associated_options = @record.send(column.association.name).collect {|r| [r.to_label, r.id]}
        select_options = associated_options | options_for_association(column.association)
        return content_tag(:span, as_(:no_options), :id => options[:id]) if select_options.empty?

        html = "<ul class=\"checkbox-list\" id=\"#{options[:id]}\">"

        associated_ids = associated_options.collect {|a| a[1]}
        select_options.each_with_index do |option, i|
          label, id = option
          this_name = "#{options[:name]}[]"
          this_id = "#{options[:id]}_#{i}_id"
          html << "<li>"
          html << check_box_tag(this_name, id, associated_ids.include?(id), :id => this_id)
          html << "<label for='#{this_id}'>"
          html << label
          html << "</label>"
          html << "</li>"
        end

        html << '</ul>'
        html << javascript_tag("new DraggableLists('#{options[:id]}')") if column.options[:draggable_lists]
        html
      end

      def active_scaffold_translated_option(column, text, value = nil)
        value = text if value.nil?
        [(text.is_a?(Symbol) ? column.active_record_class.human_attribute_name(text) : text), value.to_s]
      end

      def active_scaffold_translated_options(column)
        column.options[:options].collect do |text, value|
          active_scaffold_translated_option(column, text, value)
        end
      end

      def active_scaffold_input_select(column, html_options)
        if column.singular_association?
          active_scaffold_input_singular_association(column, html_options)
        elsif column.plural_association?
          active_scaffold_input_plural_association(column, html_options)
        else
          options = { :selected => @record.send(column.name).to_s }
          options_for_select = active_scaffold_translated_options(column)
          html_options.update(column.options[:html_options] || {})
          options.update(column.options)
          select(:record, column.name, options_for_select, options, html_options)
        end
      end

      def active_scaffold_input_radio(column, html_options)
        html_options.update(column.options[:html_options] || {})
        column.options[:options].inject('') do |html, (text, value)|
          text, value = active_scaffold_translated_option(column, text, value)
          html << content_tag(:label, radio_button(:record, column.name, value, html_options.merge(:id => html_options[:id] + '-' + value.to_s)) + text)
        end
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

      #
      # Column.type-based inputs
      #

      def active_scaffold_input_boolean(column, options)
        select_options = []
        select_options << [as_(:_select_), nil] if column.column.null
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
        path, partial_name = partial_pieces(override_subform_partial(column, subform_partial))
        template_exists?(File.join(path, "_#{partial_name}"))
      end

      def override_subform_partial(column, subform_partial)
        File.join(active_scaffold_controller_for(column.association.klass).controller_path, subform_partial) if column_renders_as(column) == :subform
      end

      def override_form_field_partial?(column)
        path, partial_name = partial_pieces(override_form_field_partial(column))
        template_exists?(File.join(path, "_#{partial_name}"), true)
      end

      # the naming convention for overriding form fields with helpers
      def override_form_field_partial(column)
        path = active_scaffold_controller_for(column.active_record_class).controller_path
        File.join(path, "#{clean_column_name(column.name)}_form_column")
      end

      def override_form_field(column)
        method = override_form_field_name(column)
        return method if respond_to?(method)
        old_method = override_form_field_name(column, true)
        if respond_to?(old_method)
          ActiveSupport::Deprecation.warn("You are using an old naming schema for overrides, you should name the helper #{method} instead of #{old_method}")
          old_method
        end
      end
      alias_method :override_form_field?, :override_form_field

      # the naming convention for overriding form fields with helpers
      def override_form_field_name(column, old = false)
        "#{clean_class_name(column.active_record_class.name) + '_' unless old}#{clean_column_name(column.name)}_form_column"
      end

      def override_input?(form_ui)
        respond_to?(override_input(form_ui))
      end

      # the naming convention for overriding form input types with helpers
      def override_input(form_ui)
        "active_scaffold_input_#{form_ui}"
      end

      def form_partial_for_column(column)
        if override_form_field_partial?(column)
          override_form_field_partial(column)
        elsif column_renders_as(column) == :field or override_form_field?(column)
          "form_attribute"
        elsif column_renders_as(column) == :subform
          "form_association"
        elsif column_renders_as(column) == :hidden
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

      def is_subsection?(column)
        column_renders_as(column) == :subsection
      end

      def is_subform?(column)
        column_renders_as(column) == :subform
      end

      def column_scope(column)
        if column.plural_association?
          "[#{column.name}][#{@record.id || generate_temporary_id}]"
        else
          "[#{column.name}]"
        end
      end

      def active_scaffold_add_existing_input(options)
        if controller.respond_to?(:record_select_config)
          remote_controller = active_scaffold_controller_for(record_select_config.model).controller_path
          options.merge!(:controller => remote_controller)
          options.merge!(active_scaffold_input_text_options)
          record_select_field(options[:name], @record, options)
        else
          column = active_scaffold_config_for(params[:parent_model]).columns[params[:parent_column]]
          select_options = options_for_select(options_for_association(column.association)) unless column.through_association?
          select_options ||= options_for_select(active_scaffold_config.model.find(:all).collect {|c| [h(c.to_label), c.id]})
          select_tag 'associated_id', '<option value="">' + as_(:_select_) + '</option>' + select_options unless select_options.empty?
        end
      end

      def active_scaffold_add_existing_label
        if controller.respond_to?(:record_select_config)
          record_select_config.model.human_name
        else
          active_scaffold_config.model.human_name
        end
      end
    end
  end
end
