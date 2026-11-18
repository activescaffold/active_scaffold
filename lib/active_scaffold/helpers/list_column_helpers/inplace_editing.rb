# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ListColumnHelpers
      module InplaceEditing
        # ==========
        # = Inline Edit =
        # ==========

        def inplace_edit?(record, column)
          return false unless column.inplace_edit
          if controller.respond_to?(:update_authorized?, true)
            return Array(controller.send(:update_authorized?, record, column.name))[0]
          end

          record.authorized_for?(crud_type: :update, column: column.name)
        end

        def inplace_edit_cloning?(column)
          column.inplace_edit != :ajax &&
            (override_form_field?(column) || column.form_ui ||
              (column.column && override_input?(column.column_type)))
        end

        def active_scaffold_inplace_edit_tag_options(record, column)
          @_inplace_edit_title ||= as_(:click_to_edit)
          cell_id = ActiveScaffold::Registry.cache :inplace_edit_id, column.cache_key do
            element_cell_id(id: '--ID--', action: 'update_column', name: column.name.to_s)
          end
          tag_options = {id: cell_id.sub('--ID--', record.id.to_s), class: 'in_place_editor_field',
                         title: @_inplace_edit_title, data: {ie_id: record.to_param}}
          tag_options[:data][:ie_update] = column.inplace_edit if column.inplace_edit != true
          tag_options
        end

        def active_scaffold_inplace_edit(record, column, options = {})
          formatted_column = options[:formatted_column] || format_column_value(record, column)
          @_inplace_edit_handle ||= content_tag(:span, as_(:inplace_edit_handle), class: 'handle')
          span = content_tag(:span, formatted_column, active_scaffold_inplace_edit_tag_options(record, column))
          @_inplace_edit_handle + span
        end

        def inplace_edit_control(column)
          return unless inplace_edit?(active_scaffold_config.model, column) && inplace_edit_cloning?(column)

          column.form_ui = :select if column.association && column.form_ui.nil?
          options = active_scaffold_input_options(column).merge(object: column.active_record_class.new)
          options[:class] = "#{options[:class]} inplace_field"
          options[:'data-id'] = options[:id]
          options[:id] = nil
          content_tag(
            :div,
            active_scaffold_input_for(column, nil, options),
            style: 'display:none;', class: inplace_edit_control_css_class
          )
        end

        def inplace_edit_control_css_class
          'as_inplace_pattern'
        end

        INPLACE_EDIT_PLURAL_FORM_UI = %i[select record_select].freeze
        def inplace_edit_data(column)
          data = _as_inplace_edit_default_data(column)
          _as_add_inplace_edit_field_data(data, column)
          _as_add_inplace_edit_mode_data(data, column)
          data
        end

        def _as_inplace_edit_default_data(column)
          {
            ie_url: url_for(params_for(action: 'update_column', column: column.name, id: '__id__')),
            ie_cancel_text: column.options[:cancel_text] || as_(:cancel),
            ie_loading_text: column.options[:loading_text] || as_(:loading),
            ie_save_text: column.options[:save_text] || as_(:update),
            ie_saving_text: column.options[:saving_text] || as_(:saving)
          }
        end

        def _as_add_inplace_edit_field_data(data, column)
          data[:ie_rows] = column.options[:rows] || 5 if column.column&.type == :text
          data[:ie_cols] = column.options[:cols] if column.options[:cols]
          data[:ie_size] = column.options[:size] if column.options[:size]
          data[:ie_use_html] = column.options[:use_html] if column.options[:use_html]
        end

        def _as_add_inplace_edit_mode_data(data, column)
          if column.list_ui == :checkbox
            data[:ie_mode] = :inline_checkbox
          elsif inplace_edit_cloning?(column)
            data[:ie_mode] = :clone
          elsif column.inplace_edit == :ajax
            url = url_for(params_for(controller: params_for[:controller], action: 'render_field', id: '__id__',
                                     update_column: column.name))
            plural = column.association&.collection? && !override_form_field?(column) &&
                     INPLACE_EDIT_PLURAL_FORM_UI.include?(column.form_ui)
            data[:ie_render_url] = url
            data[:ie_mode] = :ajax
            data[:ie_plural] = plural
          end
        end
        private :_as_inplace_edit_default_data, :_as_add_inplace_edit_field_data, :_as_add_inplace_edit_mode_data
      end
    end
  end
end
