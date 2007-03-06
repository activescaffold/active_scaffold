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
      elsif column.association.nil? or column.ui_type == :select
        return :field
      else
        return :subform
      end
    end

    def form_partial_for_column(column)
      if override_form_field_partial?(column)
        override_form_field_partial(column)
      elsif column.association.nil? || override_form_field?(column)
        "form_attribute"
      elsif !column.association.nil?
        if column.singular_association? and column.ui_type == :select
          "form_attribute"
        elsif column.singular_association?
          'form_association_singular'
        #TODO 2007-02-23 (EJM) Level=0 - Need to check if they have the security to CRUD the association column?
        else
          "form_association"
        end
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
      available_records.collect { |model| [ model.to_label, model.id ] }
    end

    def generate_temporary_id
      (Time.now.to_f*1000).to_i.to_s
    end

    # Turns [[label, value]] into <option> tags
    # Takes optional parameter of :include_blank
    def option_tags_for(select_options, options = {})
      select_options.insert(0,["- select -",nil]) if options[:include_blank]
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