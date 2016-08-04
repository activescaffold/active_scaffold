module ActiveScaffold
  module Helpers
    module PaginationHelpers
      def pagination_ajax_link(page_number, url_options, options)
        link_to page_number, url_options.merge(:page => page_number), options.merge(:class => 'as_paginate')
      end

      def pagination_url_options(url_options = nil)
        # :id needed because rails reuse it even if we delete from params (like do_refresh_list does)
        url_options ||= params_for(:action => @pagination_action || :index, :id => params[:id])
        unless active_scaffold_config.store_user_settings
          url_options.merge!(:search => search_params) if search_params.present?
          if active_scaffold_config.list.user.user_sorting?
            column, direction = active_scaffold_config.list.user.sorting.first
            url_options.merge!(:sort => column.name, :sort_direction => direction)
          end
        end
        url_options
      end

      def pagination_ajax_links(current_page, url_options, options, inner_window, outer_window)
        start_number = current_page.number - inner_window
        end_number = current_page.number + inner_window
        start_number = 1 if start_number <= 0
        if current_page.pager.infinite?
          offsets = [20, 100]
        else
          end_number = current_page.pager.last.number if end_number > current_page.pager.last.number
        end

        html = []
        if current_page.number == 1
          last_page = 0
        else
          last_page = 1
          last_page.upto([last_page + outer_window, current_page.number - 1].min) do |num|
            html << pagination_ajax_link(num, url_options, options)
            last_page = num
          end
        end
        if current_page.pager.infinite?
          offsets.reverse.each do |offset|
            page = current_page.number - offset
            next unless page < start_number && page > last_page

            html << '..' if page > last_page + 1
            html << pagination_ajax_link(page, url_options, options)
            last_page = page
          end
        end
        html << '..' if start_number > last_page + 1

        [start_number, last_page + 1].max.upto(end_number) do |num|
          if current_page.number == num
            html << content_tag(:span, num.to_s, :class => 'as_paginate current')
          else
            html << pagination_ajax_link(num, url_options, options)
          end
        end

        if current_page.pager.infinite?
          offsets.each do |offset|
            html << '..' << pagination_ajax_link(current_page.number + offset, url_options, options)
          end
        else
          html << '..' unless end_number >= current_page.pager.last.number - outer_window - 1
          [end_number + 1, current_page.pager.last.number - outer_window].max.upto(current_page.pager.last.number) do |num|
            html << pagination_ajax_link(num, url_options, options)
          end
        end
        html.join(' ').html_safe
      end
    end
  end
end
