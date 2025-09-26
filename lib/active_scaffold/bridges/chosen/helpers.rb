# frozen_string_literal: true

require 'active_support/concern'

class ActiveScaffold::Bridges::Chosen
  module Helpers
    extend ActiveSupport::Concern
    included do
      include FormColumnHelpers
      include SearchColumnHelpers
    end

    module FormColumnHelpers
      # requires RecordSelect plugin to be installed and configured.
      def active_scaffold_input_chosen(column, html_options, ui_options: column.options)
        html_options[:class] << ' chosen'
        if column.association&.collection?
          record = html_options.delete(:object)
          associated_options, select_options = active_scaffold_plural_association_options(column, record)
          options = {selected: associated_options.collect(&:id), include_blank: as_(:_select_), object: record}

          html_options.update(multiple: true).update(ui_options[:html_options] || {})
          options.update(ui_options)
          active_scaffold_select_name_with_multiple html_options

          if (optgroup = options.delete(:optgroup))
            select(:record, column.name, active_scaffold_grouped_options(column, select_options, optgroup), options, html_options)
          else
            collection_select(:record, column.name, select_options, :id, ui_options[:label_method] || :to_label, options, html_options)
          end
        else
          html = active_scaffold_input_select(column, html_options, ui_options: ui_options)
          html << active_scaffold_add_new(column, record, options, ui_options: ui_options) if ui_options[:add_new]
          html
        end
      end
    end

    module SearchColumnHelpers
      def active_scaffold_search_chosen(column, options, ui_options: column.options)
        options[:class] << ' chosen'
        active_scaffold_search_select(column, options, ui_options: ui_options)
      end

      def active_scaffold_search_multi_chosen(column, options, ui_options: column.options)
        options[:class] << ' chosen'
        options[:multiple] = true
        options[:'data-placeholder'] = ui_options[:placeholder] || as_(:_select_)
        active_scaffold_search_select(column, options, ui_options: ui_options)
      end
    end
  end
end

ActionView::Base.class_eval { include ActiveScaffold::Bridges::Chosen::Helpers }
