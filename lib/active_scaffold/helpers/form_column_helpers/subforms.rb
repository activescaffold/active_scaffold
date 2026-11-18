# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      module Subforms
        def active_scaffold_render_subform_column(column, scope, crud_type, readonly, add_class: false, record: nil,
                                                  form_columns: nil)
          col_class = _as_subform_column_class(column, record) if add_class
          if (readonly && !record.new_record?) || !record.authorized_for?(crud_type: crud_type, column: column.name)
            form_attribute(column, record, scope, only_value: true, col_class: col_class)
          else
            renders_as = column_renders_as(column)
            html = render_column(
              column, record, renders_as, scope,
              only_value: false, col_class: col_class, form_columns: form_columns
            )
            html = content_tag(:div, html, active_scaffold_subform_attributes(column)) if renders_as == :subform
            html
          end
        end

        def _as_subform_column_class(column, record)
          classes = []
          classes << 'required' if column.required?(action_for_validation(record))
          classes << column.css_class unless column.css_class.nil? || column.css_class.is_a?(Proc)
          classes << 'hidden' if column_renders_as(column) == :hidden
          classes << 'checkbox' if column.form_ui == :checkbox
          classes.join(' ')
        end
        private :_as_subform_column_class

        def active_scaffold_subform_attributes(column, column_css_class = nil, klass = nil, tab_id: nil,
                                               ui_options: column.options)
          layout = subform_layout(column, klass, ui_options)
          {
            class: "sub-form #{layout}-sub-form #{column_css_class} #{column.name}-sub-form",
            id: sub_form_id(association: column.name, tab_id: tab_id)
          }
        end

        def active_scaffold_subform_record_actions(association_column, record, locked, scope)
          # association_column nil when called for batch_create for example
          return if locked || association_column&.association&.singular?

          auth = %i[destroy delete_all delete].exclude?(association_column&.association&.dependent)
          auth, reason = record.authorized_for?(crud_type: :delete, reason: true) unless auth
          if auth
            attributes = as_element_attributes(:subform_record_remove, class: 'destroy')
            link_to(as_(:remove), '#', attributes)
          else
            as_element(:subform_record_remove_reason, reason)
          end
        end

        # Should this column be displayed in the subform?
        def in_subform?(column, parent_record, parent_column)
          # parent_column nil when called for batch_create for example
          return true if parent_column.nil? || column.association.nil?

          if column.association.reverse.nil?
            # Polymorphic associations can't appear because they *might* be the reverse association
            return false if column.association.polymorphic?

            # A column shouldn't be in the subform if it's the reverse association to the parent
            !column.association.inverse_for?(parent_record.class)
          elsif column.association.reverse == parent_column.name
            if column.association.polymorphic?
              column.association.name != parent_column.association.as
            else
              !column.association.inverse_for?(parent_record.class)
            end
          else
            true
          end
        end

        def column_show_add_existing(column, record = nil)
          column.allow_add_existing && options_for_association_count(column.association, record).positive?
        end

        def column_show_add_new(column, associated, record)
          assoc = column.association
          value = assoc.singular?
          value ||= assoc.collection? && !assoc.readonly? && (!assoc.through? || !assoc.through_reflection.collection?)
          value &&= false unless assoc.klass.authorized_for?(crud_type: :create)
          value
        end

        ##
        ## Form column override signatures
        ##

        def partial_for_model(model, partial)
          controller = active_scaffold_controller_for(model)
          while controller.uses_active_scaffold?
            path = File.join(controller.controller_path, partial)
            return path if template_exists?(path, partial: true)

            controller = controller.superclass
          end
          nil
        end

        # add functionality for overriding subform partials from association class path
        def override_subform_partial(column, subform_partial)
          partial_for_model(column.association.klass, subform_partial) if column_renders_as(column) == :subform
        end

        # the naming convention for overriding form fields with helpers
        def override_form_field_partial(column)
          partial_for_model(column.active_record_class, "#{clean_column_name(column.name)}_form_column")
        end

        def override_form_field(column)
          override_helper column, 'form_column'
        end
        alias override_form_field? override_form_field

        # the naming convention for overriding form input types with helpers
        def override_input(form_ui)
          method = "active_scaffold_input_#{form_ui}"
          method if respond_to? method
        end
        alias override_input? override_input

        def subform_partial_for_column(column, klass = nil, ui_options: column.options)
          subform_partial = "#{subform_layout(column, klass, ui_options)}_subform"
          override_subform_partial(column, subform_partial) || subform_partial
        end

        def subform_layout(column, klass, ui_options)
          ui_options[:layout] || active_scaffold_config_for(klass || column.association.klass).subform.layout
        end

        def column_scope(column, scope = nil, record = nil, generated_id = nil)
          if column.association&.collection?
            "#{scope}[#{column.name}][#{record.id || generate_temporary_id(record, generated_id)}]"
          else
            "#{scope}[#{column.name}]"
          end
        end

        def active_scaffold_add_existing_input(options)
          record = options.delete(:object)
          if controller.respond_to?(:record_select_config, true)
            remote_controller = active_scaffold_controller_for(record_select_config.model).controller_path
            options[:controller] = remote_controller
            options.merge!(active_scaffold_input_text_options)
            record_select_field(options[:name], nil, options)
          else
            helper_method = association_helper_method(nested.association, :sorted_association_options_find)
            select_options = send(helper_method, nested.association, nil, record)
            select_options ||= active_scaffold_config.model.all
            select_options = options_from_collection_for_select(select_options, :id, :to_label)
            unless select_options.empty?
              select_tag 'associated_id', (content_tag(:option, as_(:_select_), value: '') + select_options)
            end
          end
        end

        def active_scaffold_add_existing_label
          if controller.respond_to?(:record_select_config, true)
            record_select_config.model.model_name.human
          else
            active_scaffold_config.model.model_name.human
          end
        end
      end
    end
  end
end
