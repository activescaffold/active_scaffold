# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ActionLinkHelpers
      module Presentation
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
          replacements = _as_action_link_url_replacements(link, record)
          url_options.collect! do |k, v|
            [k.to_s, replacements[v] || v]
          end
          [missing_options, url_options]
        end

        def _as_action_link_url_replacements(link, record)
          replacements = {}
          replacements['--ID--'] = record.id.to_s if record
          if link.column&.association&.singular?
            replacements['--CHILD_ID--'] = record.send(link.column.association.name)&.id.to_s
          elsif nested?
            replacements['--CHILD_ID--'] = params[nested.param_name].to_s
          end
          replacements
        end
        private :_as_action_link_url_replacements

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
          link_id = cache ? '--LINK_ID--' : options[:link_id] || get_action_link_id(link, record)
          html_options = options[:html_options] || link.html_options
          html_options = html_options.merge(class: [html_options[:class], link.action.to_s].compact.join(' '))
          html_options[:link] = action_link_text(link, record, options)

          _as_add_action_link_method_and_data(html_options, link, record, cache)
          _as_add_inline_action_link_options(html_options, link, record, cache) if _as_inline_action_link?(link,
                                                                                                           options)
          _as_add_toggle_action_link_options(html_options, link, record, cache) if link.toggle
          _as_add_popup_action_link_options(html_options, link, options) if _as_popup_action_link?(link, options)
          html_options[:id] = link_id
          html_options
        end

        def _as_add_action_link_method_and_data(html_options, link, record, cache)
          # Needs to be in html_options as adding _method to the URL is no longer supported by Rails.
          html_options[:method] = link.method if link.method != :get
          html_options[:data] ||= {}
          html_options[:data] = html_options[:data].deep_dup if html_options[:data].frozen?
          html_options[:data][:confirm] = cache ? '--CONFIRM--' : link.confirm(h(record&.to_label)) if link.confirm?
        end

        def _as_add_inline_action_link_options(html_options, link, record, cache)
          html_options[:class] += ' as_action'
          html_options[:data][:position] = link.position if link.position
          html_options[:data][:action] = link.action
          html_options[:data][:cancel_refresh] = true if link.refresh_on_close
          html_options[:data][:keep_open] = true if link.keep_open?
          _as_add_action_link_prompt(html_options, link, record, cache) if link.prompt?
          html_options[:remote] = true
        end

        def _as_inline_action_link?(link, options)
          !options[:page] && !options[:popup] && (options[:inline] || link.inline?)
        end

        def _as_add_action_link_prompt(html_options, link, record, cache)
          html_options[:data][:prompt] = cache ? '--PROMPT--' : link.prompt(h(record&.to_label))
          html_options[:data][:prompt_required] = true if link.prompt_required?
        end

        def _as_add_toggle_action_link_options(html_options, link, record, cache)
          html_options[:class] += ' toggle'
          if cache
            html_options[:class] << ' --ACTIVE--'
          elsif action_link_selected?(link, record)
            html_options[:class] << ' active'
          end
        end

        def _as_popup_action_link?(link, options)
          !options[:page] && !options[:inline] && (options[:popup] || link.popup?)
        end

        def _as_add_popup_action_link_options(html_options, link, options)
          html_options[:target] = '_blank'
          html_options[:rel] = [html_options[:rel], 'noopener noreferrer'].compact.join(' ')
        end
        private :_as_add_action_link_method_and_data, :_as_add_inline_action_link_options,
                :_as_inline_action_link?, :_as_add_action_link_prompt,
                :_as_add_toggle_action_link_options, :_as_popup_action_link?, :_as_add_popup_action_link_options

        def get_action_link_id(link, record = nil)
          column = link.column unless link.is_a?(ActiveScaffold::DataStructures::ActionLinks)
          id = column&.association ? _as_association_action_link_id(column, record) : record.id&.to_s if record
          id ||= nested? ? nested_parent_id.to_s : ''
          action_link_id = ActiveScaffold::Registry.cache(:action_link_id, link.name_to_cache.to_s) { _as_cached_action_link_id(link) }
          action_link_id.sub('--ID--', id)
        end

        def _as_cached_action_link_id(link)
          return action_link_id(link.path.tr('.', '_'), '--ID--') if link.is_a?(ActiveScaffold::DataStructures::ActionLinks)

          if params[:parent_controller] || (link.controller && link.controller != controller.controller_path)
            controller_id = id_from_controller("#{link.controller}-")
          end
          action_link_id("#{controller_id}#{link.action}", '--ID--')
        end

        def _as_association_action_link_id(column, record)
          associated = record.send(column.association.name) unless column.association.collection?
          return "#{column.association.name}-#{record.id}" unless associated

          "#{column.association.name}-#{associated.id}-#{record.id}"
        end
        private :_as_association_action_link_id, :_as_cached_action_link_id

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
end
