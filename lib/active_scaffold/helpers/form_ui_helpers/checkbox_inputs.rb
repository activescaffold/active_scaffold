# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module FormUiHelpers
      module CheckboxInputs
        def active_scaffold_input_checkboxes(column, options, ui_options: column.options)
          if column.association&.singular?
            raise ArgumentError,
                  "association #{column.association.name} is singular, but checkboxes form_ui expects a collection"
          end

          if column.association # collection
            active_scaffold_input_plural_association(column, options, ui_options: ui_options)
          else
            record = options.delete(:object)
            associated_options = record.send(column.name) || []
            unless associated_options.is_a?(Array)
              raise ArgumentError, 'checkboxes form_ui expect getter to return an Array'
            end

            select_options = active_scaffold_translated_enum_options(column, options[:object], ui_options: ui_options)
            active_scaffold_checkbox_list(column, select_options, associated_options, options, ui_options: ui_options)
          end
        end

        def active_scaffold_checkbox_option(option, label_method, associated_ids, checkbox_options, item_options = {})
          content_tag(:li, item_options) do
            option_id = option.is_a?(Array) ? option[1] : option.id
            label = option.is_a?(Array) ? option[0] : option.send(label_method)
            check_box_tag(checkbox_options[:name], option_id, associated_ids.include?(option_id), checkbox_options) <<
              content_tag(:label, label, for: checkbox_options[:id])
          end
        end

        def active_scaffold_check_all_buttons(column, options, ui_options: column.options)
          content_tag(:div, class: 'check-buttons') do
            link_to(as_(:check_all), '#', class: 'check-all') <<
              link_to(as_(:uncheck_all), '#', class: 'uncheck-all')
          end
        end

        def active_scaffold_checkbox_list(column, select_options, associated_ids, options, ui_options: column.options)
          label_method = ui_options[:label_method] || :to_label
          html = active_scaffold_check_all_buttons(column, options, ui_options: ui_options)
          html << hidden_field_tag("#{options[:name]}[]", '', id: nil)
          draggable = options.delete(:draggable_lists) || ui_options[:draggable_lists]
          list_class = "#{options[:class]} checkbox-list#{' draggable-lists' if draggable}"
          html << content_tag(:ul, options.merge(class: list_class)) do
            content = []
            select_options.each_with_index do |option, i|
              option_options = {name: "#{options[:name]}[]", id: "#{options[:id]}_#{i}_id"}
              content << active_scaffold_checkbox_option(
                option, label_method, associated_ids, option_options, ui_options[:item_options] || {}
              )
            end
            safe_join content
          end
          html
        end

        def active_scaffold_input_draggable(column, options, ui_options: column.options)
          active_scaffold_input_checkboxes(column, options.merge(draggable_lists: true), ui_options: ui_options)
        end
      end
    end
  end
end
