module ActionView::Helpers
  module ActiveScaffoldFormHelpers
    def render_form_field_for_column(column)
      # first check for an override helper
      override_helper = "#{column.name}_form_column"
      return send(override_helper, @record) if respond_to? override_helper

      ## In the absence of an override use the partial based on column type
      return render :partial => form_partial_for_column(column), :locals => { :column => column }
    end

    def form_partial_for_column(column)
      column.association.nil? ? "form_attribute" : "form_association"
    end

    # TODO Make it work correctly for different types of associations
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

  end
end