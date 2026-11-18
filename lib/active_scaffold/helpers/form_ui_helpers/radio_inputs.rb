# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module FormUiHelpers
      module RadioInputs
        def active_scaffold_radio_option(option, selected, column, radio_options, ui_options: column.options)
          if column.association
            label_method = ui_options[:label_method] || :to_label
            text = option.send(label_method)
            value = option.id
            checked = {checked: selected == value}
          else
            text, value = option
          end

          id_key = radio_options[:'data-id'] ? :'data-id' : :id
          radio_options = radio_options.merge(id_key => "#{radio_options[id_key]}-#{value.to_s.parameterize}")
          radio_options.merge!(checked) if checked
          content_tag(:label, radio_button(:record, column.name, value, radio_options) + text)
        end

        def active_scaffold_input_radio_content(column, record, options, html_options, ui_options)
          add_new_subform = _as_add_new_subform?(ui_options)
          radio_html_options = _as_radio_html_options(column, html_options, ui_options, add_new_subform)

          selected = record.send(column.association.name) if column.association
          radios = options.map do |option|
            active_scaffold_radio_option(option, selected&.id, column, radio_html_options, ui_options: ui_options)
          end

          _as_add_blank_radio_option(radios, column, html_options, ui_options) if ui_options[:include_blank]
          if ui_options[:add_new]
            ui_options, skip_link = _as_add_new_radio_option(radios, selected, html_options, ui_options,
                                                             add_new_subform)
            radios << active_scaffold_add_new(column, record, html_options, ui_options: ui_options,
                                                                            skip_link: skip_link)
          end

          safe_join radios
        end

        def _as_add_new_subform?(ui_options)
          ui_options[:add_new] && (ui_options[:add_new] == true || ui_options[:add_new][:mode].in?([nil, :subform]))
        end

        def _as_radio_html_options(column, html_options, ui_options, add_new_subform)
          return html_options unless ui_options[:add_new]

          if add_new_subform
            html_options[:data] ||= {}
            html_options[:data][:subform_id] = active_scaffold_subform_attributes(column, ui_options: ui_options)[:id]
          end
          html_options.merge(class: "#{html_options[:class]} hide-new-subform")
        end

        def _as_add_blank_radio_option(radios, column, html_options, ui_options)
          label = ui_options[:include_blank]
          label = as_(label) if label.is_a?(Symbol)
          radio_id = "#{html_options[:id]}-"
          radios.prepend content_tag(:label,
                                     radio_button(:record, column.name, '', html_options.merge(id: radio_id)) + label)
        end

        def _as_add_new_radio_option(radios, selected, html_options, ui_options, add_new_subform)
          if add_new_subform
            radios << _as_new_subform_radio(selected, html_options, ui_options)
            [ui_options, true]
          else
            ui_options = _as_popup_radio_options(html_options, ui_options)
            radios << content_tag(:span, '', class: 'new-radio-container', id: html_options[:id])
            [ui_options, nil]
          end
        end

        def _as_new_subform_radio(selected, html_options, ui_options)
          content_tag(:label) do
            radio_button_tag(html_options[:name], '', selected&.new_record?, html_options.merge(
              id: "#{html_options[:id]}-create_new", class: "#{html_options[:class]} show-new-subform"
            ).except(:object)) << active_scaffold_add_new_text(ui_options[:add_new], :add_new_text, :create_new)
          end
        end

        def _as_popup_radio_options(html_options, ui_options)
          ui_options.merge(add_new: ui_options[:add_new].merge(
            url_options: {
              parent_scope: html_options[:name].gsub(/^record|\[[^\]]*\]$/, '').presence,
              radio_data: html_options.slice(*html_options.keys.grep(/^data-update_/))
            }
          ))
        end
        private :_as_add_new_subform?, :_as_radio_html_options, :_as_add_blank_radio_option, :_as_add_new_radio_option,
                :_as_new_subform_radio, :_as_popup_radio_options

        def active_scaffold_input_radio(column, html_options, ui_options: column.options)
          record = html_options[:object]
          html_options.merge!(ui_options[:html_options] || {})
          options =
            if column.association
              helper_method = association_helper_method(column.association, :sorted_association_options_find)
              send(helper_method, column.association, nil, record)
            else
              active_scaffold_translated_enum_options(column, record, ui_options: ui_options)
            end

          html =
            if options.present?
              active_scaffold_input_radio_content(column, record, options, html_options, ui_options)
            else
              active_scaffold_input_radio_without_options(column, record, html_options, ui_options)
            end
          if ui_options[:refresh_link]
            html << active_scaffold_refresh_link(
              column, html_options, record,
              ui_options.merge(field_selector: "[name=\"#{html_options[:name]}\"]")
            )
          end
          html
        end

        def active_scaffold_input_radio_without_options(column, record, html_options, ui_options)
          html = content_tag(:span, as_(:no_options), class: "#{html_options[:class]} no-options")
          html << hidden_field_tag(html_options[:name], '', id: html_options[:id])
          if ui_options[:add_new]
            html = content_tag(:div, html, class: 'select-field') <<
                   active_scaffold_add_new(column, record, html_options, ui_options: ui_options)
          end
          html
        end
        private :active_scaffold_input_radio_without_options
      end
    end
  end
end
