# frozen_string_literal: true

require 'active_support/concern'

class ActiveScaffold::Bridges::Choices
  module Helpers
    extend ActiveSupport::Concern

    included do
      include FormColumnHelpers
      include SearchColumnHelpers
      include HumanConditionHelpers
    end

    def active_scaffold_choices_ui_options(html_options, ui_options)
      choices_ui_options = ui_options.dup
      choices_html_options = (ui_options[:html_options] || {}).dup
      choices_class = [html_options[:class], choices_html_options[:class], 'as-choices'].compact.join(' ')
      html_options[:class] = choices_class
      choices_html_options[:class] = choices_class
      choices_ui_options[:html_options] = choices_html_options
      choices_ui_options
    end
    private :active_scaffold_choices_ui_options

    module FormColumnHelpers
      def active_scaffold_input_choices(column, html_options, ui_options: column.options)
        ui_options = active_scaffold_choices_ui_options(html_options, ui_options)
        html_options[:multiple] = true if column.association&.collection?
        active_scaffold_input_select(column, html_options, ui_options: ui_options)
      end
    end

    module SearchColumnHelpers
      def active_scaffold_search_choices(column, options, ui_options: column.options)
        ui_options = active_scaffold_choices_ui_options(options, ui_options)
        active_scaffold_search_select(column, options, ui_options: ui_options)
      end

      def active_scaffold_search_multi_choices(column, options, ui_options: column.options)
        ui_options = active_scaffold_choices_ui_options(options, ui_options)
        active_scaffold_search_select_multiple(column, options, ui_options: ui_options)
      end
    end

    module HumanConditionHelpers
      def active_scaffold_human_condition_choices(column, associated)
        active_scaffold_human_condition_select(column, associated)
      end

      def active_scaffold_human_condition_multi_choices(column, associated)
        active_scaffold_human_condition_select(column, associated)
      end
    end
  end
end

ActionView::Base.class_eval { include ActiveScaffold::Bridges::Choices::Helpers }
