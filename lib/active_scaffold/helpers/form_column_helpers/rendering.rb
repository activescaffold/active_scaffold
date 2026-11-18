# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module FormColumnHelpers
      module Rendering
        def column_renders_as(column)
          if column.respond_to? :each
            :subsection
          elsif column.active_record_class.locking_column.to_s == column.name.to_s || column.form_ui == :hidden
            :hidden
          elsif column.association.nil? || column.form_ui ||
                active_scaffold_config_for(column.association.klass).actions.exclude?(:subform) ||
                override_form_field?(column)
            :field
          else
            :subform
          end
        end

        def field_attributes(column, record)
          {}
        end

        def render_subsection(column, record, scope, form_action, partial: 'form', subsection_id: nil, &)
          subsection_id ||= sub_section_id(sub_section: column.label)
          locals = {columns: column, form_action: form_action, scope: scope}
          header = as_element(:form_subsection_header) do
            h(column.label) <<
              link_to_visibility_toggle(subsection_id, default_visible: !column.collapsed)
          end
          if column.tabbed_by
            locals[:tabbed_by] = column.tabbed_by
            header << content_tag(:div, id: subsection_id) do
              active_scaffold_tabbed_by(column, record, scope, subsection_id) do |tab_value, tab_id|
                render partial, locals.merge(
                  subsection_id: "#{subsection_id}-#{tab_id}", tab_id: tab_id, tab_value: tab_value
                )
              end
            end
          elsif block_given?
            header << capture(subsection_id, &)
          else
            header << render(partial, locals.merge(subsection_id: subsection_id))
          end
        end

        def render_column(column, record, renders_as, scope = nil, only_value: false, col_class: nil, form_columns: nil,
                          **subform_locals)
          hide_column, clear = form_column_is_hidden?(column, record, scope)
          if hide_column
            if clear
              form_hidden_attribute(column, record, scope, clear: true)
            else
              # creates an element that can be replaced by the update_columns routine,
              # but will not affect the value of the submitted form in this state:
              # <dl><input type="hidden" class="<%= column.name %>-input"></dl>
              content_tag :dl, style: 'display: none' do
                hidden_field_tag(nil, nil, class: "#{column.name}-input")
              end
            end
          elsif (partial = override_form_field_partial(column))
            field_options = {only_value: only_value, col_class: col_class, form_columns: form_columns}
            render partial, field_options.merge(column: column, scope: scope, record: record)
          elsif renders_as == :field || override_form_field?(column)
            field_options = {only_value: only_value, col_class: col_class, form_columns: form_columns}
            form_attribute(column, record, scope, **field_options)
          elsif renders_as == :subform
            render 'form_association', subform_locals.slice(:tabbed_by, :tab_value, :tab_id).merge(
              column: column, scope: scope, parent_record: record
            )
          else
            form_hidden_attribute(column, record, scope)
          end
        end

        def form_ui_class(form_ui) = form_ui

        def form_column_is_hidden?(column, record, scope = nil) # rubocop:disable Naming/PredicateMethod
          if column.clear_form_column_if.nil?
            condition_to_hide = column.hide_form_column_if
            clear = false
          else
            condition_to_hide = column.clear_form_column_if
            clear = true
          end
          hide =
            if condition_to_hide.respond_to?(:call)
              condition_to_hide.call(record, column, scope)
            elsif condition_to_hide.is_a?(Symbol)
              record.send(condition_to_hide)
            else
              condition_to_hide
            end
          [hide, clear]
        end

        def column_description(column, record, scope = nil)
          desc = column.description(record, scope)
          as_element(:form_field_description, h(desc) + as_element(:form_field_description_close)) if desc.present?
        end

        def form_attribute(column, record, scope = nil, only_value: false, col_class: nil, form_columns: nil,
                           field: nil)
          column_options = active_scaffold_input_options(column, scope, object: record)
          collapsible_id = column_options.delete :collapsible_id
          attributes = field_attributes(column, record)
          attributes[:class] = "#{attributes[:class]} #{col_class}" if col_class.present?
          field ||=
            if only_value
              _as_readonly_form_field(column, record, column_options)
            else
              active_scaffold_input_for column, scope, column_options, form_columns: form_columns
            end
          if field && column.update_columns
            field = safe_join([field, loading_indicator_tag(action: :render_field, id: params[:id])])
          end
          description = column_description(column, record, scope)

          label = label_tag(label_for(column, column_options), form_column_label(column, record, scope))
          label << h(' ') << link_to_visibility_toggle(collapsible_id) if collapsible_id
          form_attribute_html(column, label, field, description, attributes, collapsible_id: collapsible_id)
        end

        def _as_readonly_form_field(column, record, column_options)
          field = content_tag(:span, show_column_value(record, column), column_options.except(:name, :object))
          return field unless column.association.nil? || column.association.belongs_to?

          # Hidden field is retained for compatibility with scalar and belongs_to columns.
          safe_join([field, hidden_field(:record, column.association&.foreign_key || column.name, column_options)])
        end
        private :_as_readonly_form_field

        def form_attribute_html(column, label, field, description, attributes, collapsible_id: nil)
          field = safe_join([field, description].compact) if description.present?
          context = {column: column}
          as_element :form_attribute, proc_options: context, **attributes do
            as_element(:form_attribute_label, label, proc_options: context) <<
              as_element(:form_attribute_field, field, proc_options: context, id: collapsible_id)
          end
        end

        def label_for(column, options)
          options[:id] unless column.form_ui == :select && column.association&.collection?
        end

        def form_column_label(column, record = nil, scope = nil)
          column.label(record, scope)
        end

        def subform_label(column, hidden)
          column.label unless hidden
        end

        def form_hidden_attribute(column, record, scope = nil, clear: false)
          content_tag :dl, style: 'display: none' do
            content_tag(:dt, '') <<
              content_tag(:dd, form_hidden_field(column, record, scope, clear: clear))
          end
        end

        def active_scaffold_column_expect_array?(column)
          ui_options = column.form_ui_options || column.options
          case column.form_ui
          when :select, :choices
            column.association&.collection? || ui_options[:multiple]
          when :select_multiple, :checkboxes, :draggable
            true
          end
        end

        def form_hidden_field(column, record, scope, clear: false)
          options = active_scaffold_input_options(column, scope)
          value = record.send(column.name) unless clear
          if column.association&.collection?
            options[:name] += '[]'
            if value.blank?
              hidden_field_tag options[:name], '', options
            else
              fields = value.map do |r|
                hidden_field_tag options[:name], r.id, options.merge(id: options[:id] + "_#{r.id}")
              end
              safe_join fields, ''
            end
          elsif column.association
            hidden_field_tag options[:name], value&.id, options
          else
            options[:name] += '[]' if active_scaffold_column_expect_array?(column)
            hidden_field_tag options[:name], value, options
          end
        end
      end
    end
  end
end
