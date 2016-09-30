module ActiveScaffold
  module Helpers
    # A bunch of helper methods to produce the common view ids
    module IdHelpers
      def id_from_controller(controller)
        ERB::Util.h controller.to_s.gsub('/', '__')
      end

      def controller_id(controller = (params[:eid] || nested_id || params[:parent_controller] || params[:controller]))
        'as_' + id_from_controller(controller)
      end

      def nested_parent_id
        nested_parent_record.id
      end

      def nested_id(controller = params[:controller])
        "#{nested.parent_scaffold.controller_path}-#{nested_parent_id}-#{controller}" if nested?
      end

      def active_scaffold_id
        "#{controller_id}-active-scaffold"
      end

      def active_scaffold_content_id
        "#{controller_id}-content"
      end

      def active_scaffold_tbody_id
        "#{controller_id}-tbody"
      end

      def active_scaffold_messages_id(options = {})
        "#{options[:controller_id] || controller_id}-messages"
      end

      def active_scaffold_calculations_id(options = {})
        "#{options[:controller_id] || controller_id}-calculations#{'-' + options[:column].name.to_s if options[:column]}"
      end

      def empty_message_id
        "#{controller_id}-empty-message"
      end

      def before_header_id
        "#{controller_id}-search-container"
      end

      def search_input_id
        "#{controller_id}-search-input"
      end

      def action_link_id(link_action, link_id)
        "#{controller_id}-#{link_action}-#{link_id}-link"
      end

      def active_scaffold_column_header_id(column)
        name = column.respond_to?(:name) ? column.name : column.to_s
        clean_id "#{controller_id}-#{name}-column"
      end

      def element_row_id(options = {})
        options[:action] ||= params[:action]
        options[:id] ||= params[:id]
        options[:id] ||= nested_parent_id if nested?
        clean_id "#{options[:controller_id] || controller_id}-#{options[:action]}-#{options[:id]}-row"
      end

      def element_cell_id(options = {})
        options[:action] ||= params[:action]
        options[:id] ||= params[:id]
        options[:id] ||= nested_parent_id if nested?
        options[:name] ||= params[:name]
        clean_id "#{controller_id}-#{options[:action]}-#{options[:id]}-#{options[:name]}-cell"
      end

      def element_form_id(options = {})
        options[:action] ||= params[:action]
        options[:id] ||= params[:id]
        options[:id] ||= nested_parent_id if nested?
        clean_id "#{controller_id}-#{options[:action]}-#{options[:id]}-form"
      end

      def association_subform_id(column)
        klass = column.association.klass.to_s.underscore
        clean_id "#{controller_id}-associated-#{klass}"
      end

      def loading_indicator_id(options = {})
        options[:action] ||= params[:action]
        options[:id] ||= params[:id]
        options[:id] ||= nested_parent_id if nested?
        clean_id "#{controller_id}-#{options[:action]}-#{options[:id]}-loading-indicator"
      end

      def sub_section_id(options = {})
        options[:id] ||= params[:id]
        options[:id] ||= nested_parent_id if nested?
        clean_id "#{controller_id}-#{options[:id]}-#{options[:sub_section]}-subsection"
      end

      def sub_form_id(options = {})
        options[:id] ||= params[:id]
        options[:id] ||= nested_parent_id if nested?
        clean_id "#{controller_id}-#{options[:id]}-#{options[:association]}-subform"
      end

      def sub_form_list_id(options = {})
        options[:id] ||= params[:id]
        options[:id] ||= nested_parent_id if nested?
        clean_id "#{controller_id}-#{options[:id]}-#{options[:association]}-subform-list"
      end

      def element_messages_id(options = {})
        options[:action] ||= params[:action]
        options[:id] ||= params[:id]
        options[:id] ||= nested_parent_id if nested?
        clean_id "#{controller_id}-#{options[:action]}-#{options[:id]}-messages"
      end

      def action_iframe_id(options)
        "#{controller_id}-#{options[:action]}-#{options[:id]}-iframe"
      end

      def scope_id(scope)
        scope.gsub(/(\[|\])/, '_').gsub('__', '_').gsub(/_$/, '')
      end

      private

      # whitelists id-safe characters
      def clean_id(val)
        val.gsub /[^-_0-9a-zA-Z]/, '-'
      end
    end
  end
end
