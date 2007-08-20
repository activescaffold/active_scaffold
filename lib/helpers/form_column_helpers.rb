module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumns
      # This method decides which input to use for the given column.
      # It does not do any rendering. It only decides which method is responsible for rendering.
      def active_scaffold_input_for(column, scope = nil)
        options = active_scaffold_input_options(column.name, scope)

        # first, check if the dev has created an override for this specific field
        if override_form_field?(column)
          send(override_form_field(column), @record, options[:name])

        # second, check if the dev has specified a valid form_ui for this column
        elsif column.form_ui and override_input?(column.form_ui)
          send(override_input(column.form_ui), column, options)

        # fallback: we get to make the decision
        else
          if column.association
            # note: i'm not sure if this branch would ever get used. left to our own devices, we render associations as subforms. only if form_ui == :select do we render selects/checkboxes ... and that routing goes through the active_scaffold_input_select method.
            raise "Tell the ActiveScaffold team: I'm a real boy!"
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
              options = active_scaffold_input_text_options(options) if text_types.include?(column.column.type)

              input(:record, column.name, options)
            end
          end
        end
      end

      alias form_column active_scaffold_input_for

      # the standard active scaffold options used for textual inputs
      def active_scaffold_input_text_options(options = {})
        options[:autocomplete] = 'off'
        options[:size] = 20
        options[:class] = "#{options[:class]} text-input".strip
        options
      end

      # the standard active scaffold options used for class, name and scope
      def active_scaffold_input_options(column_name, scope = nil)
        name = scope ? "record#{scope}[#{column_name}]" : "record[#{column_name}]"
        options = { :name => name, :class => "#{column_name}-input" }
      end

      ##
      ## Autocomplete support for :form_ui => :auto_complete
      ##

      def active_scaffold_input_singular_association_with_auto_complete(column, options)
        if associated = @record.send(column.association.name)
          value_id = associated.id
          value = associated.to_label
        end

        input_name = "#{options[:name]}[id]" # "record[#{column.name}][id]"
        input_id = input_name.gsub("[", "_").gsub("]", "") # "record_#{column.name}_id"
        id_tag = hidden_field_tag(input_name, value_id, {:id => input_id})

        companion_name = "record[#{column.name}_companion]"
        companion_id = "record_#{column.name}_companion"
        text_tag = text_field_tag(companion_name, value, active_scaffold_input_text_options.merge(:id => companion_id))

        container_tag = content_tag("div", "", :id => "#{companion_id}_auto_complete", :class => "auto_complete")

        styling = column.options[:skip_style] ? "" : auto_complete_stylesheet

        autocomplete_magic = auto_complete_field(companion_id,
          :url => { :action => :auto_complete_column, :column => column.name, :id => @record.id },
          :after_update_element => "function(text_box, selected_list_item) {
            Element.cleanWhitespace(selected_list_item);
            var text = selected_list_item.childNodes[0].firstChild.nodeValue;
            var id = selected_list_item.childNodes[1].firstChild.nodeValue;
            if (id) {
              text_box.value = text;
              $('#{input_id}').value = id;
            }
          }"
        )

        return styling + id_tag + text_tag + container_tag + autocomplete_magic
      end

      # we can't use auto_complete_result because we want the hidden id field.
      def active_scaffold_auto_responder(entries)
        items = entries.map { |entry|
          active_scaffold_auto_responder_item(entry.to_label, entry.id.to_s)
        }
        items = [active_scaffold_auto_responder_item(as_('No Entries'), nil)] if items.length == 0
        content_tag("ul", items.uniq, :class => "autocomplete_list")
      end

      def active_scaffold_auto_responder_item(label, id)
        content_tag("li",
          content_tag('span', label, :class => "autocomplete_item") +
          content_tag('span', id, :style => "visibility:hidden;")
        )
      end

      ##
      ## Form input methods
      ##

      def active_scaffold_input_singular_association(column, options)
        associated = @record.send(column.association.name)

        select_options = [[as_('- select -'),nil]]
        select_options += [[ associated.to_label, associated.id ]] unless associated.nil?
        select_options += options_for_association(column.association)

        selected = associated.nil? ? nil : associated.id

        options[:name] += '[id]'
        select(:record, column.name, select_options.uniq, { :selected => selected }, options)
      end

      def active_scaffold_input_plural_association(column, options)
        associated_options = @record.send(column.association.name).collect {|r| [r.to_label, r.id]}
        select_options = associated_options | options_for_association(column.association)
        return 'no options' if select_options.empty?

        html = '<ul class="checkbox-list">'

        associated_ids = associated_options.collect {|a| a[1]}
        select_options.each_with_index do |option, i|
          label, id = option
          this_name = "#{options[:name]}[#{i}][id]"
          html << "<li>"
          html << check_box_tag(this_name, id, associated_ids.include?(id))
          html << "<label for='#{this_name}'>"
          html << label
          html << "</label>"
          html << "</li>"
        end

        html << '</ul>'
        html
      end

      def active_scaffold_input_auto_complete(column, options)
        if column.singular_association?
          active_scaffold_input_singular_association_with_auto_complete(column, options)
        else
          # there's no mechanism yet for autocompleting plural associations or regular attributes
          active_scaffold_input_select(column, options)
        end
      end

      def active_scaffold_input_select(column, options)
        if column.singular_association?
          active_scaffold_input_singular_association(column, options)
        elsif column.plural_association?
          active_scaffold_input_plural_association(column, options)
        else
          select(:record, column.name, column.options, { :selected => @record.send(column.name) }, options)
        end
      end

      # only works for singular associations
      # requires RecordSelect plugin to be installed and configured.
      # ... maybe this should be provided in a bridge?
      def active_scaffold_input_record_select(column, options)
        remote_controller = active_scaffold_controller_for(column.association.klass).controller_path

        # if the opposite association is a :belongs_to, then only show records that have not been associated yet
        params = if column.association and [:has_one, :has_many].include?(column.association.macro)
          {column.association.primary_key_name => ''}
        else
          {}
        end

        if column.singular_association?
          record_select_field(
            "#{options[:name]}[id]",
            @record.send(column.name) || column.association.klass.new,
            {:controller => remote_controller, :params => params}.merge(column.options)
          )
        elsif column.plural_association?
          record_multi_select_field(
            options[:name],
            @record.send(column.name),
            {:controller => remote_controller, :params => params}.merge(column.options)
          )
        end
      end

      def active_scaffold_input_checkbox(column, options)
        check_box(:record, column.name, options)
      end

      def active_scaffold_input_country(column, options)
        priority = ["United States"]
        select_options = {:prompt => as_('- select -')}
        select_options.merge!(options)
        country_select(:record, column.name, column.options[:priority] || priority, select_options, column.options)
      end

      def active_scaffold_input_password(column, options)
        password_field :record, column.name, active_scaffold_input_text_options(options)
      end

      def active_scaffold_input_textarea(column, options)
        text_area(:record, column.name, options.merge(:cols => column.options[:cols], :rows => column.options[:rows]))
      end

      def active_scaffold_input_usa_state(column, options)
        select_options = {:prompt => as_('- select -')}
        select_options.merge!(options)
        select_options.delete(:size)
        options.delete(:prompt)
        options.delete(:priority)
        usa_state_select(:record, column.name, column.options[:priority], select_options, column.options.merge!(options))
      end

      def active_scaffold_input_virtual(column, options)
        text_field :record, column.name, active_scaffold_input_text_options(options)
      end

      #
      # Column.type-based inputs
      #

      def active_scaffold_input_boolean(column, options)
        select_options = []
        select_options << [as_('- select -'), nil] if column.column.null
        select_options << [as_('True'), true]
        select_options << [as_('False'), false]

        select_tag(options[:name], options_for_select(select_options, @record.send(column.name)))
      end

      ##
      ## Form column override signatures
      ##

      def override_form_field_partial?(column)
        path, partial_name = partial_pieces(override_form_field_partial(column))
        file_exists? File.join(path, "_#{partial_name}")
      end

      # the naming convention for overriding form fields with partials
      def override_form_field_partial(column)
        "#{column.name}_form_column"
      end

      def override_form_field?(column)
        respond_to?(override_form_field(column))
      end

      # the naming convention for overriding form fields with helpers
      def override_form_field(column)
        "#{column.name}_form_column"
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

      ##
      ## Macro-level rendering decisions for columns
      ##

      def column_renders_as(column)
        if column.is_a? ActiveScaffold::DataStructures::ActionColumns
          return :subsection
        elsif column.active_record_class.locking_column.to_s == column.name.to_s
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
    end
  end
end
