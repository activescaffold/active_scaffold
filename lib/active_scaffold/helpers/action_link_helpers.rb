# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    # Helpers rendering action links
    module ActionLinkHelpers
      # params which mustn't be copying to nested links
      NESTED_PARAMS = %i[eid embedded association parent_scaffold].freeze

      def skip_action_link?(link, *args)
        !link.ignore_method.nil? && controller.respond_to?(link.ignore_method, true) && controller.send(link.ignore_method, *args)
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
        html = content_tag :ul, ul_options do
          safe_join(links.map { |link| content_tag :li, link })
        end
        raw "ActiveScaffold.display_dynamic_action_group('#{get_action_link_id action_link, record}', '#{escape_javascript html}');" # rubocop:disable Rails/OutputSafety
      end

      def display_action_links(action_links, record, options, &block)
        options[:level_0_tag] ||= nil
        options[:options_level_0_tag] ||= nil
        options[:level] ||= 0
        options[:first_action] = true
        output = ActiveSupport::SafeBuffer.new
        prev_link = separator = nil

        action_links.each(reverse: options.delete(:reverse), groups: true) do |link|
          if link == :separator
            separator = true if prev_link
            next
          end
          content = nil
          if link.is_a? ActiveScaffold::DataStructures::ActionLinks
            content = display_action_link_group(link, record, options, &block) unless link.empty?
          elsif !skip_action_link?(link, *Array(options[:for]))
            authorized, reason = action_link_authorized?(link, *Array(options[:for]))
            next if !authorized && options[:skip_unauthorized]

            content = display_action_link(link, nil, record, options.merge(authorized: authorized, not_authorized_reason: reason))
            options[:first_action] = false
          end
          next if content.blank?

          prev_link = true
          output << display_action_link_separator(options) if separator
          output << content
          separator = false
        end
        output
      end

      def display_action_link_group(link, record, options, &)
        options[:level] += 1
        content = display_action_links(link, record, options, &)
        options[:level] -= 1
        display_action_link(link, content, record, options).tap { options[:first_action] = false } if content.present?
      end

      def display_action_link_separator(options)
        tag = options[:level_0_tag] || :a if options[:level].zero?
        content_tag(tag || :li, '&nbsp;'.html_safe, class: 'separator')
      end

      def display_action_link(link, content, record, options)
        if content
          html_classes = hover_via_click? ? 'hover_click ' : ''
          if options[:level].zero?
            html_classes += 'action_group'
            group_tag = :div
          else
            html_classes += 'top' if options[:first_action]
            group_tag = :li
          end
          content = content_tag(group_tag, class: html_classes.presence, onclick: ('' if hover_via_click?)) do
            content_tag(:div, link.label(record), class: link.css_class, title: options[:title]) << content_tag(:ul, content)
          end
        else
          content = render_action_link(link, record, options)
          content = content_tag(:li, content, class: ('top' if options[:first_action])) unless options[:level].zero?
        end
        content = content_tag(options[:level_0_tag], content, options[:options_level_0_tag]) if options[:level].zero? && options[:level_0_tag]
        content
      end

      def render_action_link(link, record = nil, options = {})
        if link.action.nil? || link.column&.association&.polymorphic?
          link = action_link_to_inline_form(link, record) if link.column&.association
          options[:authorized] = false if link.action.nil? || link.controller.nil?
          options.delete :link if link.crud_type == :create
        end
        method =
          if link.action.nil? || (link.type == :member && options.key?(:authorized) && !options[:authorized])
            :render_unauthorized_action_link
          else
            :render_authorized_action_link
          end

        cache_link = cache_action_link?(link)
        label = options[:link]
        result = optional_cache_helper(method, link.name_to_cache.to_s, cache_link, link, record, options, cache: cache_link)
        cache_link ? replace_tags_for_action_link(result, method, link, label, record, options) : result
      end

      def optional_cache_helper(method, key, cache, *args, **kwargs, &)
        if cache
          ActiveScaffold::Registry.cache(method, key) { send(method, *args, **kwargs, &) }
        else
          send(method, *args, **kwargs, &)
        end
      end

      def replace_tags_for_action_link(html, method, link, label, record, options)
        case method
        when :render_unauthorized_action_link
          html = html.gsub('--REASON--', ERB::Util.unwrapped_html_escape(options[:not_authorized_reason]))
        when :render_authorized_action_link
          html = html.gsub('--URL--', ERB::Util.unwrapped_html_escape(action_link_url(link, record)))
                   .gsub('--LINK_ID--', ERB::Util.unwrapped_html_escape(get_action_link_id(link, record)))
                   .gsub('--CONFIRM--') { ERB::Util.unwrapped_html_escape(link.confirm(h(record&.to_label))) }
                   .gsub('--PROMPT--') { ERB::Util.unwrapped_html_escape(link.prompt(h(record&.to_label))) }
                   .gsub('--ACTIVE--') { action_link_selected?(link, record) ? 'active' : '' }
        end
        html&.gsub('--LABEL--', h(label || link.label(record)))&.html_safe
      end

      def render_unauthorized_action_link(link, record = nil, options = {}, cache: false)
        html_class = "disabled #{link.action}#{" #{link.html_options[:class]}" if link.html_options[:class].present?}"
        options[:link] = '--LABEL--' if cache
        html_options = {
          link: action_link_text(link, record, options),
          class: html_class,
          title: cache ? '--REASON--' : options[:not_authorized_reason]
        }
        html = action_link_html(link, nil, html_options, record)
        cache ? html.to_str : html
      end

      def render_authorized_action_link(link, record = nil, options = {}, cache: false)
        url = cache ? '--URL--' : action_link_url(link, record)
        options[:link] = '--LABEL--' if cache
        html_options = action_link_html_options(link, record, options, cache: cache)
        html = action_link_html(link, url, html_options, record)
        cache ? html.to_str : html
      end

      # setup the action link to inline form
      def action_link_to_inline_form(link, record)
        link = link.dup
        associated = record.send(link.column.association.name)
        if link.column.association&.polymorphic? || link.controller.nil?
          link.controller = controller_path_for_activerecord(associated.class)
          return link if link.controller.nil?
        end
        link = configure_column_link(link, record, associated) if link.action.nil?
        link
      end

      def configure_column_link(link, record, associated, actions = nil)
        actions ||= link.controller_actions || []
        if column_empty?(associated) # if association is empty, we only can link to create form
          if actions.include?(:new)
            link.action = 'new'
            link.crud_type = :create
            link.label ||= :create_new
          end
        elsif actions.include?(:edit)
          link.action = 'edit'
          link.crud_type = :update
        elsif actions.include?(:show)
          link.action = 'show'
          link.crud_type = :read
        elsif actions.include?(:list)
          link.action = 'index'
          link.crud_type = :read
        end

        unless column_link_authorized?(link, link.column, record, associated)[0]
          link.action = nil
          # if action is edit and is not authorized, fallback to show if it's enabled
          if link.crud_type == :update && actions.include?(:show)
            link = configure_column_link(link, record, associated, [:show])
          end
        end
        link
      end

      def column_link_authorized?(link, column, record, associated)
        if column.association
          associated_for_authorized =
            if column.association.collection? || associated.nil?
              column.association.klass
            else
              associated
            end
          authorized, reason = associated_for_authorized.authorized_for?(crud_type: link.crud_type, reason: true)
          if link.crud_type == :create && authorized
            authorized, reason = record.authorized_for?(crud_type: :update, column: column.name, reason: true)
          end
          [authorized, reason]
        else
          action_link_authorized?(link, record)
        end
      end

      def sti_record?(record)
        return false unless active_scaffold_config.active_record?

        model = active_scaffold_config.model
        record && model.columns_hash.include?(model.inheritance_column) &&
          record[model.inheritance_column].present? && !record.instance_of?(model)
      end

      def cache_action_link_url?(link, record)
        active_scaffold_config.user.cache_action_link_urls && link.type == :member && !link.dynamic_parameters.is_a?(Proc) && !sti_record?(record)
      end

      def cache_action_link?(link)
        active_scaffold_config.user.cache_action_links && link.type == :member
      end

      def cached_action_link_url(link, record)
        @action_links_urls ||= {}
        @action_links_urls[link.name_to_cache.to_s] || begin
          url_options = cached_action_link_url_options(link, record)
          if cache_action_link_url?(link, record)
            @action_links_urls[link.name_to_cache.to_s] = url_for(url_options)
          else
            url_options.merge! eid: nil, embedded: nil if link.nested_link?
            url_for(params_for(url_options))
          end
        end
      end

      def replace_id_params_in_action_link_url(link, record, url)
        url = record ? url.sub('--ID--', record.to_param.to_s) : url.dup
        if link.column&.association&.singular?
          child_id = record.send(link.column.association.name)&.to_param
          if child_id.present?
            url.sub!('--CHILD_ID--', child_id)
          else
            url.sub!(/\w+=--CHILD_ID--&?/, '')
            url.sub!(/\?$/, '')
          end
        elsif nested?
          url.sub!('--CHILD_ID--', params[nested.param_name].to_s)
        end
        url
      end

      def add_query_string_to_cached_url(link, url)
        query_string, non_nested_query_string = query_string_for_action_links(link)
        nested_params = !link.nested_link? && non_nested_query_string
        if query_string || nested_params
          url << (url.include?('?') ? '&' : '?')
          url << query_string if query_string
          url << non_nested_query_string if nested_params
        end
        url
      end

      def action_link_url(link, record)
        url = replace_id_params_in_action_link_url(link, record, cached_action_link_url(link, record))
        url = add_query_string_to_cached_url(link, url) if @action_links_urls[link.name_to_cache.to_s]
        url
      end

      def column_in_params_conditions?(key)
        if key.match?(/!$/)
          conditions_from_params[1..].any? { |node| node.left.name.to_s == key[0..-2] }
        else
          conditions_from_params[0].include?(key)
        end
      end

      def ignore_param_for_nested?(key)
        NESTED_PARAMS.include?(key) || column_in_params_conditions?(key) || (nested? && nested.param_name == key)
      end

      def query_string_for_action_links(link)
        if defined?(@query_string) && link.parameters.none? { |k, _| @query_string_params.include? k }
          return [@query_string, @non_nested_query_string]
        end

        keep = true
        @query_string_params ||= Set.new
        query_string_options = {}
        non_nested_query_string_options = {}

        params_for.except(:controller, :action, :id).each do |key, value|
          @query_string_params << key
          if link.parameters.include? key
            keep = false
            next
          end
          if ignore_param_for_nested?(key)
            non_nested_query_string_options[key] = value
          else
            query_string_options[key] = value
          end
        end
        if nested_singular_association? && action_name == 'index'
          # pass current path as return_to, for nested listing on singular association, so forms doesn't return to parent listing
          @query_string_params << :return_to
          non_nested_query_string_options[:return_to] = request.fullpath
        end

        query_string = query_string_options.to_query if query_string_options.present?
        if non_nested_query_string_options.present?
          non_nested_query_string = "#{'&' if query_string}#{non_nested_query_string_options.to_query}"
        end
        if keep
          @query_string = query_string
          @non_nested_query_string = non_nested_query_string
        end
        [query_string, non_nested_query_string]
      end

      def cache_action_link_url_options?(link, record)
        active_scaffold_config.user.cache_action_link_urls && (link.type == :collection || !link.dynamic_parameters.is_a?(Proc)) && !sti_record?(record)
      end

      def cached_action_link_url_options(link, record)
        optional_cache_helper(:action_link_url_options, link.name_to_cache.to_s, cache_action_link_url_options?(link, record), link, record)
      end

      def action_link_url_options(link, record)
        url_options = {action: link.action}
        url_options[:id] = '--ID--' unless record.nil?
        url_options[:controller] = link.controller.to_s if link.controller
        url_options.merge! link.parameters if link.parameters
        if link.dynamic_parameters.is_a?(Proc)
          if record.nil?
            url_options.merge! instance_exec(&link.dynamic_parameters)
          else
            url_options.merge! instance_exec(record, &link.dynamic_parameters)
          end
        end
        if link.nested_link?
          url_options_for_nested_link(link.column, record, link, url_options)
        elsif nested?
          url_options[nested.param_name] = '--CHILD_ID--'
        end
        url_options_for_sti_link(link.column, record, link, url_options) unless record.nil? || active_scaffold_config.sti_children.nil?
        url_options[:_method] = link.method if !link.confirm? && link.inline? && link.method != :get
        url_options
      end

      def action_link_text(link, record, options)
        if link.image
          title = options[:link] || link.label(record)
          asset = ActiveScaffold::Registry.cache(:link_images, link.image[:name]) { image_path(link.image[:name]) }
          text = image_tag(asset, size: link.image[:size], alt: title, title: title, skip_pipeline: true)
        end
        text || options[:link]
      end

      def replaced_action_link_url_options(link, record)
        url = cached_action_link_url_options(link, record)
        url[:controller] ||= params[:controller]
        missing_options, url_options = url.partition { |_, v| v.nil? }
        replacements = {}
        replacements['--ID--'] = record.id.to_s if record
        if link.column&.association&.singular?
          replacements['--CHILD_ID--'] = record.send(link.column.association.name)&.id.to_s
        elsif nested?
          replacements['--CHILD_ID--'] = params[nested.param_name].to_s
        end
        url_options.collect! do |k, v|
          [k.to_s, replacements[v] || v]
        end
        [missing_options, url_options]
      end

      def action_link_selected?(link, record)
        if link.respond_to?(:filter_name)
          if params[link.filter_name]
            params[link.filter_name].to_s == link.name.to_s
          else
            active_scaffold_config.list.filters[link.filter_name].default_option == link.name
          end
        else
          missing_options, url_options = replaced_action_link_url_options(link, record)
          safe_params = params.to_unsafe_h
          (url_options - safe_params.to_a).blank? && missing_options.all? { |k, _| params[k].nil? }
        end
      end

      def action_link_html_options(link, record, options, cache: false)
        link_id = cache ? '--LINK_ID--' : get_action_link_id(link, record)
        html_options = options[:html_options] || link.html_options
        html_options = html_options.merge(class: [html_options[:class], link.action.to_s].compact.join(' '))
        html_options[:link] = action_link_text(link, record, options)

        # Needs to be in html_options to as the adding _method to the url is no longer supported by Rails
        html_options[:method] = link.method if link.method != :get

        html_options[:data] ||= {}
        html_options[:data] = html_options[:data].deep_dup if html_options[:data].frozen?
        html_options[:data][:confirm] = cache ? '--CONFIRM--' : link.confirm(h(record&.to_label)) if link.confirm?
        if !options[:page] && !options[:popup] && (options[:inline] || link.inline?)
          html_options[:class] += ' as_action'
          html_options[:data][:position] = link.position if link.position
          html_options[:data][:action] = link.action
          html_options[:data][:cancel_refresh] = true if link.refresh_on_close
          html_options[:data][:keep_open] = true if link.keep_open?
          if link.prompt?
            html_options[:data][:prompt] = cache ? '--PROMPT--' : link.prompt(h(record&.to_label))
            html_options[:data][:prompt_required] = true if link.prompt_required?
          end
          html_options[:remote] = true
        end

        if link.toggle
          html_options[:class] += ' toggle'
          if cache
            html_options[:class] << ' --ACTIVE--'
          elsif action_link_selected?(link, record)
            html_options[:class] << ' active'
          end
        end

        if !options[:page] && !options[:inline] && (options[:popup] || link.popup?)
          html_options[:target] = '_blank'
          html_options[:rel] = [html_options[:rel], 'noopener noreferrer'].compact.join(' ')
        end
        html_options[:id] = link_id
        html_options
      end

      def get_action_link_id(link, record = nil)
        column = link.column
        if column&.association && record
          associated = record.send(column.association.name) unless column.association.collection?
          id =
            if associated
              "#{column.association.name}-#{associated.id}-#{record.id}"
            else
              "#{column.association.name}-#{record.id}"
            end
        end
        id ||= record&.id&.to_s || (nested? ? nested_parent_id.to_s : '')
        action_link_id = ActiveScaffold::Registry.cache :action_link_id, link.name_to_cache.to_s do
          if params[:parent_controller] || (link.controller && link.controller != controller.controller_path)
            controller_id = id_from_controller("#{link.controller}-")
          end
          action_link_id("#{controller_id}#{link.action}", '--ID--')
        end
        action_link_id.sub('--ID--', id)
      end

      def action_link_html(link, url, html_options, record)
        label = html_options.delete(:link)
        label ||= link.label(record)
        if url.nil?
          content_tag(:a, label, html_options)
        else
          link_to(label, url, html_options)
        end
      end

      def url_options_for_nested_link(column, record, link, url_options)
        if column&.association
          url_options[:parent_scaffold] = controller_path
          url_options[column.model.name.foreign_key.to_sym] = url_options.delete(:id)
          url_options[:id] = ('--CHILD_ID--' if column.association.singular? && url_options[:action].to_sym != :index)
        elsif link.parameters&.dig(:named_scope)
          url_options[:parent_scaffold] = controller_path
          url_options[active_scaffold_config.model.name.foreign_key.to_sym] = url_options.delete(:id)
          url_options[:id] = nil
        end
      end

      def url_options_for_sti_link(column, record, link, url_options)
        # need to find out controller of current record type and set parameters
        # it's quite difficult to detect an sti link
        # if link.column.nil? we are sure that it isn't a singular association inline autolink
        # however that will not work if a sti parent is a singular association inline autolink
        return unless link.column.nil?
        return if (sti_controller_path = controller_path_for_activerecord(record.class)).nil?

        url_options[:controller] = sti_controller_path
        url_options[:parent_sti] = controller_path
      end
    end
  end
end
