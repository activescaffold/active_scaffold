module ActiveScaffold
  module Helpers
    # Helpers rendering filters
    module FilterHelpers
      def display_filters(filters)
        content = []
        filters.each do |filter|
          content << display_filter(filter)
        end
        content_tag :div, safe_join(content), class: 'filters' if content.present?
      end

      def display_filter(filter)
        return if filter.security_method && !controller.send(filter.security_method)
        options = filter.reject { |option| option.security_method && !controller.send(option.security_method) }
        send "display_filter_as_#{filter.type}", filter, options if options.present?
      end

      def display_filter_as_links(filter, options)
        content_tag(:div, class: 'action_group') do
          content_tag(:div, filter.label, class: filter.css_class, title: filter.description) <<
            content_tag(:ul, safe_join(display_filter_options_as_links(options)))
        end
      end

      def display_filter_options_as_links(options)
        options.map do |option|
          html_options = {class: "toggle #{'active' if params[option.filter_name] == option.name.to_s}"}
          content_tag :li, render_action_link(option, nil, authorized: true, link: option.label, html_options: html_options)
        end
      end
    end
  end
end
