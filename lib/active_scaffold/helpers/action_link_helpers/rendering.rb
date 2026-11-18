# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ActionLinkHelpers
      module Rendering
        def skip_action_link?(link, *)
          return false if link.ignore_method.nil?

          controller.respond_to?(link.ignore_method, true) && controller.send(link.ignore_method, *)
        end

        def action_link_authorized?(link, *args) # rubocop:disable Naming/PredicateMethod
          auth, reason =
            if link.security_method_set? || controller.respond_to?(link.security_method, true)
              controller.send(link.security_method, *args)
            else
              args.empty? || args.first.authorized_for?(crud_type: link.crud_type, action: link.action, reason: true)
            end
          [auth, reason]
        end

        def display_dynamic_action_group(action_link, links, record_or_ul_options = nil, ul_options = nil)
          ul_options = record_or_ul_options if ul_options.nil? && record_or_ul_options.is_a?(Hash)
          record = record_or_ul_options unless record_or_ul_options.is_a?(Hash)
          ul_options ||= {}
          ul_options[:class] = [ul_options[:class], 'dynamic-menu'].compact.join(' ')
          html = as_element :dynamic_action_group, **ul_options do
            safe_join(links.map { |link| as_element :dynamic_action_group_element, link })
          end
          safe_join([
                      'ActiveScaffold.display_dynamic_action_group(',
                      javascript_literal(get_action_link_id(action_link, record)),
                      ', ',
                      javascript_literal(html),
                      ');'
                    ])
        end

        def display_action_links(action_links, record, options, &block)
          options[:level_0_tag] ||= nil
          options[:options_level_0_tag] ||= nil
          options[:level] ||= 0
          options[:first_action] = true
          output = options.delete(:output) || ActiveSupport::SafeBuffer.new
          prev_link = separator = nil

          action_links.each(reverse: options.delete(:reverse), groups: true) do |link|
            if link == :separator
              separator = true if prev_link
              next
            end
            content = _as_action_link_content(link, record, options, &block)
            next if content.blank?

            prev_link = true
            output << display_action_link_separator(options) if separator
            output << content
            separator = false
          end
          output
        end

        def _as_action_link_content(link, record, options, &)
          if link.is_a? ActiveScaffold::DataStructures::ActionLinks
            display_action_link_group(link, record, options, &) unless link.empty?
          elsif !skip_action_link?(link, *Array(options[:for]))
            authorized, reason = action_link_authorized?(link, *Array(options[:for]))
            return if !authorized && options[:skip_unauthorized]

            content = display_action_link(link, nil, record,
                                          options.merge(authorized: authorized, not_authorized_reason: reason))
            options[:first_action] = false
            content
          end
        end
        private :_as_action_link_content

        def display_action_link_group(link, record, options, &)
          if link.click_menu?
            display_click_menu_link(link, record, options)
          else
            options[:level] += 1
            content = display_action_links(link, record, options, &)
            options[:level] -= 1
            if content.present?
              display_action_link(link, content, record, options).tap do
                options[:first_action] = false
              end
            end
          end
        end

        def display_action_link_separator(options)
          as_element(:action_link_separator, '&nbsp;'.html_safe, proc_options: options)
        end

        def display_click_menu_link(link, record, options)
          action_link =
            if link.path.start_with?('collection.')
              ActiveScaffold::DataStructures::ActionLinks::COLLECTION_CLICK_MENU_LINK
            else
              ActiveScaffold::DataStructures::ActionLinks::MEMBER_CLICK_MENU_LINK
            end
          html = display_action_link(
            action_link,
            nil,
            record,
            options.merge(authorized: true, link: link.label(record), link_id: get_action_link_id(link, record))
          )
          html.gsub('--ACTION-LINKS--', ERB::Util.unwrapped_html_escape(link.path)).html_safe # rubocop:disable Rails/OutputSafety
        end

        def display_action_link(link, content, record, options)
          if content
            content = render_action_link_group(link, content, record, options)
          else
            content = render_action_link(link, record, options)
            unless options[:level].zero?
              context = {link: link, record: record, options: options}
              content = as_element(
                :action_link_item,
                content,
                proc_options: context,
                class: ('top' if options[:first_action])
              )
            end
          end
          if options[:level].zero? && options[:level_0_tag]
            content = content_tag(options[:level_0_tag], content, options[:options_level_0_tag])
          end
          content
        end

        def render_action_link_group(link, content, record, options, group_label: nil)
          context = options.merge(link: link, record: record)
          as_element(:action_link_group, proc_options: context) do
            as_element(
              :action_link_group_title,
              group_label || link.label(record),
              proc_options: context,
              class: link.css_class,
              title: options[:title]
            ) << as_element(:action_link_group_content, content, proc_options: context)
          end
        end

        def render_action_link(link, record = nil, options = {})
          link = _as_prepare_action_link(link, record, options)
          method = _as_action_link_render_method(link, options)

          cache_link = cache_action_link?(link)
          label = options[:link]
          result = optional_cache_helper(method, link.name_to_cache.to_s, cache_link, link, record, options,
                                         cache: cache_link)
          cache_link ? replace_tags_for_action_link(result, method, link, label, record, options) : result
        end

        def _as_prepare_action_link(link, record, options)
          return link unless link.action.nil? || link.column&.association&.polymorphic?

          link = action_link_to_inline_form(link, record) if link.column&.association
          options[:authorized] = false if link.action.nil? || link.controller.nil?
          options.delete :link if link.crud_type == :create
          link
        end

        def _as_action_link_render_method(link, options)
          unauthorized = link.action.nil? ||
                         (link.type == :member && options.key?(:authorized) && !options[:authorized])
          unauthorized ? :render_unauthorized_action_link : :render_authorized_action_link
        end
        private :_as_prepare_action_link, :_as_action_link_render_method

        def replace_tags_for_action_link(html, method, link, label, record, options) # rubocop:disable Metrics/ParameterLists
          case method
          when :render_unauthorized_action_link
            html = html.gsub('--REASON--', ERB::Util.unwrapped_html_escape(options[:not_authorized_reason]))
          when :render_authorized_action_link
            html = html.gsub('--URL--', ERB::Util.unwrapped_html_escape(action_link_url(link, record)))
                     .gsub('--LINK_ID--', ERB::Util.unwrapped_html_escape(
                                            options[:link_id] || get_action_link_id(link, record)
                                          ))
                     .gsub('--CONFIRM--') { ERB::Util.unwrapped_html_escape(link.confirm(h(record&.to_label))) }
                     .gsub('--PROMPT--') { ERB::Util.unwrapped_html_escape(link.prompt(h(record&.to_label))) }
                     .gsub('--ACTIVE--') { action_link_selected?(link, record) ? 'active' : '' }
          end
          html&.gsub('--LABEL--', h(label || link.label(record)))&.html_safe # rubocop:disable Rails/OutputSafety
        end

        def render_unauthorized_action_link(link, record = nil, options = {}, cache: false)
          html_class = "disabled #{link.action}#{" #{link.html_options[:class]}" if link.html_options[:class].present?}"
          options[:link] = '--LABEL--' if cache
          html_options = {
            link: action_link_text(link, record, options),
            class: html_class,
            title: cache ? '--REASON--' : options[:not_authorized_reason]
          }
          html_options = action_link_element_attributes(link, record, options, html_options, authorized: false)
          html = action_link_html(link, nil, html_options, record)
          cache ? html.to_str : html
        end

        def render_authorized_action_link(link, record = nil, options = {}, cache: false)
          url = cache ? '--URL--' : action_link_url(link, record)
          options[:link] = '--LABEL--' if cache
          html_options = action_link_html_options(link, record, options, cache: cache)
          html_options = action_link_element_attributes(link, record, options, html_options, authorized: true)
          html = action_link_html(link, url, html_options, record)
          cache ? html.to_str : html
        end

        def action_link_element_attributes(link, record, options, attributes, authorized:)
          context = {link: link, record: record, options: options, authorized: authorized}
          as_element_attributes(:action_link, proc_options: context, **attributes)
        end
      end
    end
  end
end
