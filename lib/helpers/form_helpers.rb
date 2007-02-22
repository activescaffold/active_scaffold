module ActionView::Helpers
  module ActiveScaffoldFormHelpers
    def render_form_field_for_column(column)
      # first check for an override helper
      override_helper = "#{column.name}_form_column"
      return send(override_helper, @record) if respond_to? override_helper

      ## In the absence of an override use the partial based on column type
      return render(:partial => form_partial_for_column(column), :locals => { :column => column })
    end

    def form_partial_for_column(column)
      column.association.nil? ? "form_attribute" : "form_association"
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