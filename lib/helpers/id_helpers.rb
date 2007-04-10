module ActionView::Helpers
  # A bunch of helper methods to produce the common view ids
  module ActiveScaffoldIdHelpers
    def controller_id
      @controller_id ||= params[:controller].gsub("/", "__")
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

    def active_scaffold_messages_id
      "#{controller_id}-messages"
    end

    def empty_message_id
      "#{controller_id}-empty-message"
    end

    def before_header_id
      "#{controller_id}-search-container"
    end

    def search_form_id
      "#{controller_id}-search-form"
    end

    def search_input_id
      "#{controller_id}-search-input"
    end

    def active_scaffold_column_header_id(column)
      name = column.respond_to?(:name) ? column.name : column.to_s
      clean_id "#{controller_id}-#{name}-column"
    end

    def element_row_id(options = {})
      options[:action] ||= params[:action]
      options[:id] ||= params[:id]
      options[:id] = "#{options[:id]}@"
      clean_id "#{controller_id}-#{options[:action]}-#{options[:id]}-row"
    end

    def element_cell_id(options = {})
      options[:action] ||= params[:action]
      options[:id] ||= params[:id]
      clean_id "#{controller_id}-#{options[:action]}-#{options[:id]}-cell"
    end

    def element_form_id(options = {})
      options[:action] ||= params[:action]
      options[:id] ||= params[:id]
      clean_id "#{controller_id}-#{options[:action]}-#{options[:id]}-form"
    end

    def association_subform_id(column)
      klass = column.association.klass.to_s.underscore
      clean_id "#{controller_id}-associated-#{klass}"
    end

    def loading_indicator_id(options = {})
      options[:action] ||= params[:action]
      unless options[:id]
        clean_id "#{controller_id}-#{options[:action]}-loading-indicator"
      else
        clean_id "#{controller_id}-#{options[:action]}-#{options[:id]}-loading-indicator"
      end
    end

    def sub_form_id(options = {})
      options[:id] ||= params[:id]
      clean_id "#{controller_id}-#{options[:id]}-#{options[:association]}-subform"
    end

    def sub_form_list_id(options = {})
      options[:id] ||= params[:id]
      clean_id "#{controller_id}-#{options[:id]}-#{options[:association]}-subform-list"
    end

    def element_messages_id(options = {})
      options[:action] ||= params[:action]
      options[:id] ||= params[:id]
      clean_id "#{controller_id}-#{options[:action]}-#{options[:id]}-messages"
    end

    private

    # whitelists id-safe characters
    def clean_id(val)
      val.gsub /[^-._0-9a-zA-Z]/, '-'
    end
  end
end
