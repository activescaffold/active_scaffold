module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module FormColumns
      def form_column(column, scope = nil)
        name = scope ? "record#{scope}[#{column.name}]" : "record[#{column.name}]"
        if override_form_field?(column)
          send(override_form_field(column), @record, name)
        elsif column.singular_association?
          select_options = [[as_('- select -'),nil]]
          # Need to add as options all current associations for this record
          associated = @record.send(column.association.name)
          select_options += [[ associated.to_label, associated.id ]] unless associated.nil?
          select_options += options_for_association(column.association)
          selected = associated.nil? ? nil : associated.id
          select(:record, column.name, select_options.uniq, { :selected => selected }, { :name => "#{name}[id]", :class => "#{column.name}-input" })

        elsif column.plural_association?

          html = '<ul class="checkbox-list">'

          associated = @record.send(column.association.name).collect {|r| r.id}
          options = association_options_find(column.association).collect {|r| [r.to_label, r.id]}.sort_by {|o| o.first}
          return 'no options' if options.empty?

          options.each_with_index do |option, i|
            label, id = option
            this_name = "#{name}[#{i}][id]"
            html << "<li>"
            html << check_box_tag(this_name, id, associated.include?(id))
            html << "<label for='#{this_name}'>"
            html << label
            html << "</label>"
            html << "</li>"
          end

          html << '</ul>'
          html
        else
          options = { :name => name, :class => "#{column.name}-input" }
          active_scaffold_input(column, options)
        end
      end

      def active_scaffold_input(column, options)
        text_options = options.merge( :autocomplete => "off", :size => 20, :class => "#{column.name}-input text-input" )
        if column.form_ui and override_input?(column.form_ui)
          send(override_input(column.form_ui), column, options, text_options)
        elsif column.virtual?
          active_scaffold_input_virtual(column, options, text_options)
        elsif column.type and override_input?(column.type)
          send(override_input(column.type), column, options, text_options)
        elsif [:text, :string, :integer, :float, :decimal].include?(column.column.type)
          input(:record, column.name, text_options)
        else
          input(:record, column.name, options)
        end
      end

      ##
      ## Form input methods
      ##
      def active_scaffold_input_boolean(column, options, text_options)
        select_options = []
        select_options << [as_('- select -'), nil] if column.column.null
        select_options << [as_('True'), true]
        select_options << [as_('False'), false]

        select_tag(options[:name], options_for_select(select_options, @record.send(column.name)))
      end

      def active_scaffold_input_checkbox(column, options, text_options)
        check_box(:record, column.name, options)
      end

      def active_scaffold_input_password(column, options, text_options)
        password_field :record, column.name, text_options              
      end

      def active_scaffold_input_virtual(column, options, text_options)
        text_field(:record, column.name, text_options)
      end      
      
      ##
      ## Form column overrides
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

      def override_input?(ui_type)
        respond_to?(override_input(ui_type))
      end

      # the naming convention for overriding form input types with helpers
      def override_input(ui_type)
        "active_scaffold_input_#{ui_type}"
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
        elsif column.association.nil? or column.ui_type == :select or !active_scaffold_config_for(column.association.klass).actions.include?(:subform)
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