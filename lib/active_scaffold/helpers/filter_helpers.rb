module ActiveScaffold
  module Helpers
    # Helpers rendering filters
    module FilterHelpers
      def clear_filters_params
        active_scaffold_config.list.filters.each_with_object({}) do |filter, url_options|
          url_options[filter.name] = nil
        end
      end

      def display_filters(filters)
        content = filters.sort_by(&:weight).map { |filter| display_filter(filter) }
        as_ui_tag :filters, safe_join(content) if content.present?
      end

      def display_filter(filter)
        return if filter.security_method && !controller.send(filter.security_method)

        options = filter.reject { |option| option.security_method_set? && !controller.send(option.security_method) }
        send :"display_filter_as_#{filter.type}", filter, options if options.present?
      end

      def display_filter_as_links(filter, options)
        content = options.map { |option| display_action_link(option, nil, nil, authorized: true, level: 1) }
        display_action_link(filter, safe_join(content), nil, level: 0, title: filter.description) if content.present?
      end

      def display_filter_as_select(filter, options)
        content = options.map do |option|
          content_tag :option, option.label(nil), data: {url: action_link_url(option, nil)}, selected: action_link_selected?(option, nil), title: option.description
        end
        select_tag nil, safe_join(content), class: "action_group #{link.css_class}", title: filter.description || filter.label, data: {remote: :url} if content.present?
      end
    end
  end
end
