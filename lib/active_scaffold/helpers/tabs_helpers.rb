# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    # Helpers that assist with rendering of tabs in forms
    module TabsHelpers
      def active_scaffold_tabbed_by(column, record, scope, subsection_id, &)
        add_tab_url = params_for(action: 'render_field', tabbed_by: column.tabbed_by, id: record.to_param, column: column.label)
        refresh_opts = {refresh_link: {text: 'Add tab', class: 'refresh-link add-tab'}}
        tab_options = send(override_helper_per_model(:active_scaffold_tab_options, record.class), column, record)
        used_tabs = send(override_helper_per_model(:active_scaffold_current_tabs, record.class), column, record, tab_options)
        input_helper = override_helper_per_model(:active_scaffold_input_for_tabbed, record.class)
        send(input_helper, column, record, subsection_id, tab_options, used_tabs.map(&:first)) <<
          active_scaffold_refresh_link(nil, {'data-update_url' => url_for(add_tab_url)}, record, refresh_opts) <<
          active_scaffold_tabs_for(column, record, subsection_id, tab_options, used_tabs, &)
      end

      def active_scaffold_input_for_tabbed(column, record, subsection_id, tab_options, used_tabs)
        hidden_style = 'display: none;'
        blank_choice = content_tag(:option, as_(:_select_), value: '')
        option_tags = tab_options.inject(blank_choice) do |html, (label, value, tab_record)|
          used = used_tabs.include?(tab_record || value)
          html << content_tag(:option, label, value: value, style: (hidden_style if used))
        end
        select_tag(nil, option_tags, class: "#{column.tabbed_by}-input", id: "#{subsection_id}_input")
      end

      def active_scaffold_current_tabs(column, record, tab_options)
        used_choices = Set.new
        column.each_column do |col|
          tabbed_by = col.options[:tabbed_by] || column.tabbed_by
          tab_values = record.send(col.name).map(&tabbed_by).compact
          if tabbed_by_association(col, tabbed_by)
            tab_values.map! { |value| [value, value.id.to_s] }
          else
            tab_values.map! { |value| [tab_options.find { |_, tab_value, _| value == tab_value }&.first || value, value] }
          end
          used_choices.merge tab_values
        end
        used_choices
      end

      def active_scaffold_tab_options(column, record)
        subform_column = column.first
        if subform_column
          tabbed_by = subform_column.options[:tabbed_by] || column.tabbed_by
          if tabbed_by_association(subform_column, tabbed_by)
            subform_record = record.send(subform_column.name).first_or_initialize
            tab_column = active_scaffold_config_for(subform_column.association.klass).columns[tabbed_by]
          end
        end
        if tab_column
          label_method = (tab_column.form_ui_options || tab_column.options)[:label_method] || :to_label
          helper_method = association_helper_method(column.association, :sorted_association_options_find)
          send(helper_method, tab_column.association, nil, subform_record).map do |opt_record|
            [opt_record.send(label_method), opt_record.id, opt_record]
          end
        else
          []
        end
      end

      def active_scaffold_tab(label, tab_id, active)
        content_tag :li, class: "nav-item #{:active if active}" do
          link_to(label, "##{tab_id}", class: 'nav-link', data: {toggle: :tab})
        end
      end

      def active_scaffold_tab_content(tab_id, active, content)
        content_tag(:div, content, class: "tab-pane fade#{' in active' if active}", id: tab_id)
      end

      def active_scaffold_tabs_for(column, record, subsection_id, tab_options, used_tabs)
        used_tabs = used_tabs.map { |value, value_id| [value, clean_id(value_id || value.to_s)] }
        content_tag(:div, class: 'tabbed') do
          content_tag(:ul, class: 'nav nav-tabs') do
            tabs = used_tabs.map.with_index do |(tab_value, id), i|
              active_scaffold_tab tab_options.find { |_, value, tab_record| tab_value == (tab_record || value) }&.first, "#{subsection_id}-#{id}-tab", i.zero?
            end
            safe_join tabs
          end << content_tag(:div, class: 'tab-content') do
            tabs = used_tabs.map.with_index do |(tab_value, id), i|
              active_scaffold_tab_content("#{subsection_id}-#{id}-tab", i.zero?, yield(tab_value, id))
            end
            safe_join(tabs)
          end
        end
      end
    end
  end
end
