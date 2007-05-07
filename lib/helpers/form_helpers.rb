module ActionView::Helpers
  module ActiveScaffoldFormHelpers
    def render_form_field_for_column(column, locals = {})
      locals[:column] = column
      return render(:partial => form_partial_for_column(column), :locals => locals)
    end

    def is_subform?(column)
      column_renders_as(column) == :subform
    end

    # Should this column be displayed in the subform?
    def in_subform?(column, parent_record)
      return true unless column.association

      # Polymorphic associations can't appear because they *might* be the reverse association, and because you generally don't assign an association from the polymorphic side ... I think.
      return false if column.polymorphic_association?

      # We don't have the UI to currently handle habtm in subforms
      return false if column.association.macro == :has_and_belongs_to_many

      # A column shouldn't be in the subform if it's the reverse association to the parent
      return false if column.association.reverse_for?(parent_record.class)
      #return false if column.association.klass == parent_record.class

      return true
    end

    def is_subsection?(column)
      column_renders_as(column) == :subsection
    end

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
      if column.virtual?
        text_field(:record, column.name, text_options)
      elsif [:text, :string, :integer, :float, :decimal].include?(column.column.type)
        input(:record, column.name, text_options)
      else
        input(:record, column.name, options)
      end
    end

    def override_form_field(column)
      "#{column.name}_form_column"
    end

    def override_form_field?(column)
      respond_to?(override_form_field(column))
    end

    def override_form_field_partial(column)
      "#{column.name}_form_column"
    end

    def override_form_field_partial?(column)
      path, partial_name = partial_pieces(override_form_field_partial(column))
      file_exists? File.join(path, "_#{partial_name}")
    end

    def options_for_association(association)
      available_records = association_options_find(association, options_for_association_conditions(association))
      available_records ||= []
      available_records.sort{|a,b| a.to_label <=> b.to_label}.collect { |model| [ model.to_label, model.id ] }
    end

    def options_for_association_count(association)
      association_options_count(association, options_for_association_conditions(association))
    end

    def options_for_association_conditions(association)
      case association.macro
        when :has_one, :has_many
          # Find only orphaned objects
          "#{association.primary_key_name} IS NULL"
        when :belongs_to, :has_and_belongs_to_many
          # Find all
          nil
      end
    end

    def generate_temporary_id
      (Time.now.to_f*1000).to_i.to_s
    end

    # Turns [[label, value]] into <option> tags
    # Takes optional parameter of :include_blank
    def option_tags_for(select_options, options = {})
      select_options.insert(0,[as_('- select -'),nil]) if options[:include_blank]
      select_options.collect do |option|
        label, value = option[0], option[1]
        value.nil? ? "<option value="">#{label}</option>" : "<option value=\"#{value}\">#{label}</option>"
      end
    end

  end
end