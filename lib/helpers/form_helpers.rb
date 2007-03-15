module ActionView::Helpers
  module ActiveScaffoldFormHelpers
    def render_form_field_for_column(column, locals = {})
      locals[:column] = column
      return render(:partial => form_partial_for_column(column), :locals => locals)
    end

    def is_subform?(column)
      column_renders_as(column) == :subform
    end

    def is_subsection?(column)
      column_renders_as(column) == :subsection
    end

    def column_renders_as(column)
      if column.is_a? ActiveScaffold::DataStructures::ActionColumns
        return :subsection
      elsif column.association.nil? or column.ui_type == :select or !active_scaffold_config_for(column.association.klass).actions.include?(:subform)
        return :field
      #TODO 2007-02-23 (EJM) Level=0 - Need to check if they have the security to CRUD the association column?
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
      end
    end

    def form_column(column, scope = nil)
      name = scope ? "record#{scope}[#{column.name}]" : "record[#{column.name}]"
      if override_form_field?(column)
        send(override_form_field(column), @record)
      elsif column.singular_association?
        select_options = [[_('_SELECT_'),nil]]
        # Need to add as options all current associations for this record
        associated = @record.send(column.association.name)
        select_options += [[ associated.to_label, associated.id ]] unless associated.nil?
        select_options += options_for_association(column.association)
        selected = associated.nil? ? nil : associated.id
        select(:record, column.name, select_options.uniq, { :selected => selected }, { :name => "#{name}[id]" })
      elsif column.plural_association?
        html = '<div class="checkbox-list">'

        associated = @record.send(column.association.name).collect {|r| r.id}
        options = column.association.klass.find(:all).collect {|r| [r.to_label, r.id]}.sort_by {|o| o.first}

        options.each_with_index do |option, i|
          label, id = option
          this_name = "#{name}[#{i}][id]"
          html << "<label for='#{this_name}'>"
          html << check_box_tag(this_name, id, associated.include?(id))
          html << label
          html << "</label>"
        end

        html << '</div>'
        html
      else
        options = { :name => name }
        active_scaffold_input(column, options)
      end
    end

    def active_scaffold_input(column, options)
      text_options = options.merge( :autocomplete => "off", :size => 20, :class => 'text-input' )
      if column.virtual?
        text_field(:record, column.name, text_options)
      elsif :boolean == column.ui_type
        check_box(:record, column.name)
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
      case association.macro
        when :has_one
          available_records = association.klass.find(:all, :conditions => "#{association.primary_key_name} IS NULL")
        when :has_many
          # Find only orphaned objects
          available_records = association.klass.find(:all, :conditions => "#{association.primary_key_name} IS NULL")
        when :belongs_to
          available_records = association.klass.find(:all)
        when :has_and_belongs_to_many
          # Any
          available_records = association.klass.find(:all)
      end
      available_records ||= []
      available_records.sort{|a,b| a.to_label <=> b.to_label}.collect { |model| [ model.to_label, model.id ] }
    end

    def generate_temporary_id
      (Time.now.to_f*1000).to_i.to_s
    end

    # Turns [[label, value]] into <option> tags
    # Takes optional parameter of :include_blank
    def option_tags_for(select_options, options = {})
      select_options.insert(0,[_('_SELECT_'),nil]) if options[:include_blank]
      select_options.collect do |option|
        label, value = option[0], option[1]
        value.nil? ? "<option value="">#{label}</option>" : "<option value=\"#{value}\">#{label}</option>"
      end
    end

    # Takes a params hash and constructs hidden form inputs that match.
    def params_to_input_tags(params, scope = [])
      tags = []
      params.each do |key,value|
        local_scope = scope.dup.push(key)
        if value.is_a? Hash
          tags << params_to_input_tags(value, local_scope)
        else
          tags << "<input type=\"hidden\" name=\"#{input_name_for_scope(local_scope)}\" value=\"#{value}\" />"
        end
      end
      tags.flatten.join
    end

    # Turns ['record','name'] into 'record[name]'
    def input_name_for_scope(scope)
      scope.shift + scope.collect{ |node| "[#{node}]" }.join
    end

  end
end