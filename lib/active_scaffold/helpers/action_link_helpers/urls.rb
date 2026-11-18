# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ActionLinkHelpers
      module Urls
        def sti_record?(record)
          return false unless active_scaffold_config.active_record?

          model = active_scaffold_config.model
          record && model.columns_hash.include?(model.inheritance_column) &&
            record[model.inheritance_column].present? && !record.instance_of?(model)
        end

        def cache_action_link_url?(link, record)
          active_scaffold_config.user.cache_action_link_urls && link.type == :member &&
            !link.dynamic_parameters.is_a?(Proc) && !sti_record?(record)
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
            conditions_from_params[1..].any? { |node| condition_node_for_column?(node, key[0..-2]) }
          else
            conditions_from_params[0].include?(key)
          end
        end

        def condition_node_for_column?(node, column_name)
          return node.name.to_s == column_name if node.is_a?(Arel::Attributes::Attribute)

          %i[expr left right].any? do |child|
            node.respond_to?(child) && condition_node_for_column?(node.public_send(child), column_name)
          end
        end

        def ignore_param_for_nested?(key)
          NESTED_PARAMS.include?(key) || column_in_params_conditions?(key) || (nested? && nested.param_name == key)
        end

        def query_string_for_action_links(link)
          if defined?(@query_string) && link.parameters.none? { |k, _| @query_string_params.include? k }
            return [@query_string, @non_nested_query_string]
          end

          keep, query_string_options, non_nested_query_string_options = _as_action_link_query_options(link)
          if nested_singular_association? && action_name == 'index'
            # pass the current path as return_to, for nested listing on singular association, so forms don't return to
            # parent listing
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

        def _as_action_link_query_options(link)
          keep = true
          @query_string_params ||= Set.new
          query_options = {}
          non_nested_options = {}
          params_for.except(:controller, :action, :id).each do |key, value|
            @query_string_params << key
            if link.parameters.include? key
              keep = false
            elsif ignore_param_for_nested?(key)
              non_nested_options[key] = value
            else
              query_options[key] = value
            end
          end
          [keep, query_options, non_nested_options]
        end
        private :_as_action_link_query_options

        def cache_action_link_url_options?(link, record)
          active_scaffold_config.user.cache_action_link_urls &&
            (link.type == :collection || !link.dynamic_parameters.is_a?(Proc)) && !sti_record?(record)
        end

        def cached_action_link_url_options(link, record)
          optional_cache_helper(:action_link_url_options, link.name_to_cache.to_s,
                                cache_action_link_url_options?(link, record), link, record)
        end

        def action_link_url_options(link, record)
          url_options = {action: link.action}
          url_options[:id] = '--ID--' unless record.nil?
          url_options[:controller] = link.controller.to_s if link.controller
          url_options.merge! link.parameters if link.parameters
          _as_add_dynamic_action_link_parameters(url_options, link, record)
          _as_add_nested_action_link_parameters(url_options, link, record)
          unless record.nil? || active_scaffold_config.sti_children.nil?
            url_options_for_sti_link(link.column, record, link, url_options)
          end
          url_options[:_method] = link.method if !link.confirm? && link.inline? && link.method != :get
          url_options
        end

        def _as_add_dynamic_action_link_parameters(url_options, link, record)
          return unless link.dynamic_parameters.is_a?(Proc)

          dynamic_parameters =
            if record.nil?
              instance_exec(&link.dynamic_parameters)
            else
              instance_exec(record, &link.dynamic_parameters)
            end
          url_options.merge! dynamic_parameters
        end

        def _as_add_nested_action_link_parameters(url_options, link, record)
          if link.nested_link?
            url_options_for_nested_link(link.column, record, link, url_options)
          elsif nested?
            url_options[nested.param_name] = '--CHILD_ID--'
          end
        end
        private :_as_add_dynamic_action_link_parameters, :_as_add_nested_action_link_parameters
      end
    end
  end
end
