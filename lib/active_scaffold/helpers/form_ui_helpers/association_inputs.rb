# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module FormUiHelpers
      module AssociationInputs
        def active_scaffold_grouped_options(column, select_options, optgroup)
          group_column = active_scaffold_config_for(column.association.klass).columns[optgroup]
          group_label = group_column.options[:label_method] if group_column
          group_label ||= group_column&.association ? :to_label : :to_s
          select_options.group_by(&optgroup.to_sym).collect do |group, options|
            [group.send(group_label), options.collect do |r|
              [r.send(column.options[:label_method] || :to_label), r.id]
            end]
          end
        end

        def active_scaffold_translate_select_options(options)
          options[:include_blank] = as_(options[:include_blank].to_s) if options[:include_blank].is_a? Symbol
          options[:prompt] = as_(options[:prompt].to_s) if options[:prompt].is_a? Symbol
          options
        end

        def active_scaffold_select_name_with_multiple(options)
          return if !options[:multiple] || options[:name].to_s.ends_with?('[]')

          options[:name] = "#{options[:name]}[]"
        end

        def active_scaffold_input_singular_association(column, html_options, options = {}, ui_options: column.options)
          record = html_options.delete(:object)
          helper_method = association_helper_method(column.association, :sorted_association_options_find)
          select_options = send(helper_method, column.association, nil, record)
          _as_set_singular_association_selection(column, record, select_options, html_options, options)

          options.reverse_merge! include_blank: as_(:_select_), object: record

          html_options.merge!(ui_options[:html_options] || {})
          options.merge!(ui_options)
          active_scaffold_select_name_with_multiple html_options # doesn't make sense most of time, but AS_batch use it
          active_scaffold_translate_select_options(options)

          html = _as_singular_association_select(column, select_options, options, html_options, ui_options)
          html << active_scaffold_refresh_link(column, html_options, record, ui_options) if ui_options[:refresh_link]
          html
        end

        def _as_set_singular_association_selection(column, record, select_options, html_options, options)
          if html_options.include?(:associated)
            options[:selected] ||= html_options.delete(:associated)
          else
            associated = record.send(column.association.name)
            select_options.unshift(associated) if associated&.persisted? && select_options.exclude?(associated)
            options[:selected] ||= associated&.id
          end
        end

        def _as_singular_association_select(column, select_options, options, html_options, ui_options)
          if (optgroup = options.delete(:optgroup))
            select(:record, column.name, active_scaffold_grouped_options(column, select_options, optgroup), options,
                   html_options)
          else
            collection_select(
              :record, column.name, select_options, :id, ui_options[:label_method] || :to_label, options, html_options
            )
          end
        end
        private :_as_set_singular_association_selection, :_as_singular_association_select

        def active_scaffold_plural_association_options(column, record = nil)
          associated_options = record.send(column.association.name)
          helper_method = association_helper_method(column.association, :sorted_association_options_find)
          [associated_options, associated_options | send(helper_method, column.association, nil, record)]
        end

        def active_scaffold_input_plural_association(column, options, ui_options: column.options)
          record = options.delete(:object)
          associated_options, select_options = active_scaffold_plural_association_options(column, record)

          html =
            if options[:multiple] || ui_options.dig(:html_options, :multiple)
              html_options = options.merge(ui_options[:html_options] || {})
              active_scaffold_select_name_with_multiple html_options
              collection_select(:record, column.name, select_options, :id, ui_options[:label_method] || :to_label,
                                ui_options.merge(object: record), html_options)
            elsif select_options.empty?
              content_tag(:span, as_(:no_options), class: "#{options[:class]} no-options", id: options[:id]) <<
                hidden_field_tag("#{options[:name]}[]", '', id: nil)
            else
              active_scaffold_checkbox_list(column, select_options, associated_options.collect(&:id), options,
                                            ui_options: ui_options)
            end
          html << active_scaffold_refresh_link(column, options, record, ui_options) if ui_options[:refresh_link]
          html
        end

        def active_scaffold_new_record_klass(column, record, **options)
          if column.association.polymorphic? && column.association.belongs_to?
            type = record.send(column.association.foreign_type)
            type_options = options[:types]
            column.association.klass(record) if type.present? && (type_options.nil? || type_options.include?(type))
          else
            column.association.klass
          end
        end

        def active_scaffold_add_new(column, record, html_options, ui_options: column.options, skip_link: false)
          options = ui_options[:add_new] == true ? {} : ui_options[:add_new]
          options[:mode] = :popup if column.association&.collection?
          case options[:mode]
          when nil, :subform
            active_scaffold_new_record_subform(column, record, html_options, options: options, skip_link: skip_link)
          when :popup
            active_scaffold_new_record_popup(column, record, html_options, options: options) unless skip_link
          else
            raise ArgumentError, "unsupported mode for add_new: #{options[:mode].inspect}"
          end
        end

        def active_scaffold_new_record_url_options(column, record)
          if column.association.reverse
            constraint = [record.id]
            constraint.unshift record.class.name if column.association.reverse_association.polymorphic?
            {embedded: {constraints: {column.association.reverse => constraint}}}
          else
            raise "can't add constraint to create new record with :popup, no reverse association for " \
                  "\"#{column.name}\" in #{column.association.klass}, add the reverse association " \
                  'or override active_scaffold_new_record_url_options helper.'
          end
        end

        def active_scaffold_new_record_popup(column, record, html_options, options: {})
          klass = send(override_helper_per_model(:active_scaffold_new_record_klass, record.class), column, record,
                       **options)
          klass = nil unless _as_new_record_popup_authorized?(klass, options)
          return h('') unless klass

          link_text = active_scaffold_add_new_text(options, :add_new_text, :add)
          url_options = _as_new_record_popup_url_options(column, record, html_options, klass, options)
          attributes = as_element_attributes(
            :field_add_new_popup, remote: true, data: {position: :popup}, class: 'as_action'
          )
          link_to(link_text, signed_url_options(url_options), attributes)
        end

        def _as_new_record_popup_authorized?(klass, options)
          return controller.send(options[:security_method]) if options[:security_method]

          klass&.authorized_for?(crud_type: :create)
        end

        def _as_new_record_popup_url_options(column, record, html_options, klass, options)
          helper = override_helper_per_model(:active_scaffold_new_record_url_options, record.class)
          url_options = send(helper, column, record)
          url_options[:controller] ||= active_scaffold_controller_for(klass).controller_path
          url_options[:action] ||= :new
          url_options[:from_field] ||= html_options[:id]
          url_options[:parent_model] ||= record.class.name
          url_options[:parent_column] ||= column.name
          url_options.reverse_merge! options[:url_options] if options[:url_options]
          url_options
        end
        private :_as_new_record_popup_authorized?, :_as_new_record_popup_url_options

        def active_scaffold_new_record_subform(column, record, html_options, options: {}, new_record_attributes: nil,
                                               locals: {}, skip_link: false)
          klass = send(override_helper_per_model(:active_scaffold_new_record_klass, record.class), column, record,
                       **options)
          return content_tag(:div, '') unless klass

          subform_attrs, new_record = _as_new_record_subform_attributes(column, record, klass, options)
          scope = html_options[:name].scan(/record(.*)\[#{column.name}\]/).dig(0, 0)
          new_record ||= klass.new(new_record_attributes)
          locals = locals.reverse_merge(column: column, parent_record: record, associated: [],
                                        show_blank_record: new_record, scope: scope)
          subform = render(partial: subform_partial_for_column(column, klass, ui_options: options), locals: locals)
          if options[:hide_subgroups]
            toggable_id = "#{sub_form_id(association: column.name,
                                         id: record.id || generated_id(record) || 99_999_999_999)}-div"
            subform << link_to_visibility_toggle(toggable_id, default_visible: false)
          end
          html = content_tag(:div, subform, subform_attrs)
          return html if skip_link

          html << active_scaffold_show_new_subform_link(column, record, html_options[:id], subform_attrs[:id],
                                                        options: options)
        end

        def _as_new_record_subform_attributes(column, record, klass, options)
          attributes = active_scaffold_subform_attributes(column, nil, klass, ui_options: options)
          attributes[:class] << ' optional'

          new_record = record.send(column.name)
          if new_record&.new_record?
            [attributes, new_record]
          else
            attributes[:style] = 'display: none'
            [attributes, nil]
          end
        end
        private :_as_new_record_subform_attributes

        def active_scaffold_add_new_text(options, key, default)
          text = options[key] unless options == true
          return text if text.is_a? String

          as_(text || default)
        end

        def active_scaffold_show_new_subform_link(column, record, select_id, subform_id, options: {})
          add_existing = active_scaffold_add_new_text(options, :add_existing_text, :add_existing)
          create_new = active_scaffold_add_new_text(options, :add_new_text, :create_new)
          data = {select_id: select_id, subform_id: subform_id, subform_text: add_existing, select_text: create_new}
          label = data[record.send(column.name)&.new_record? ? :subform_text : :select_text]
          link_to(label, '#', as_element_attributes(:field_add_new_subform, data: data, class: 'show-new-subform'))
        end

        def active_scaffold_refresh_link(column, html_options, record, ui_options = {})
          link_options = _as_refresh_link_options(column, html_options, record, ui_options)
          if ui_options[:refresh_link].is_a?(Hash)
            text = ui_options.dig(:refresh_link, :text)
            text = as_(text) if text.is_a?(Symbol)
            link_options.merge! ui_options[:refresh_link].except(:text)
          end
          link_to(text || as_(:refresh), link_options.delete('data-update_url') || html_options['data-update_url'],
                  link_options.except(:object))
        end

        def _as_refresh_link_options(column, html_options, record, ui_options)
          link_options = {object: record,
                          data: {field_selector: ui_options[:field_selector] || "##{html_options[:id]}"}}
          if html_options['data-update_url']
            link_options['data-update_send_form'] = html_options['data-update_send_form']
            link_options['data-update_send_form_selector'] = html_options['data-update_send_form_selector']
          else
            if html_options[:name]
              scope = html_options[:name].scan(/^record((\[[^\]]*\])*)\[#{column.name}\]/).dig(0,
                                                                                               0)
            end
            link_options = update_columns_options(column, scope.presence, link_options, force: true)
          end
          link_options[:class] = 'refresh-link'
          link_options
        end
        private :_as_refresh_link_options
      end
    end
  end
end
