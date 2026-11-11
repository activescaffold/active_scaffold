# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module PaginationHelpers
      def pagination_ajax_link(page_number, url_options, options, text: nil)
        attributes = as_element_attributes(
          :pagination_link,
          proc_options: {page_number: page_number, text: text},
          **options.smart_merge(class: 'as_paginate')
        )
        link_to text ? as_(text) : page_number, url_options.merge(page: page_number), attributes
      end

      def pagination_url_options(url_options = nil)
        if url_options.nil?
          url_options = {action: @pagination_action || :index}
          # :id needed because rails reuse it even if it was deleted from params (like do_refresh_list does)
          url_options[:id] = nil if @remove_id_from_list_links
          url_options = params_for(url_options)
        end
        url_options
      end

      def pagination_active_page(page_number, url_options, options)
        attributes = options.slice(:id, :class).smart_merge(class: 'as_paginate current')
        as_element :pagination_active_page, page_number,
                   proc_options: {page_number: page_number}, **attributes
      end

      def pagination_gap(options)
        '..'
      end

      # Wraps the complete pagination sequence, including previous and next links.
      # UI adapters may override this method and call +super+ to add nested markup.
      def pagination_html(&)
        capture(&)
      end

      def pagination_ajax_links(current_page, url_options, options, inner_window, outer_window)
        start_number, end_number = _as_pagination_window(current_page, inner_window)
        html, last_page = _as_pagination_leading_links(current_page, url_options, options, outer_window)
        if current_page.pager.infinite?
          _as_infinite_previous_pages(current_page, start_number, last_page).each do |page|
            html << pagination_gap(options) if page > last_page + 1
            html << pagination_ajax_link(page, url_options, options)
            last_page = page
          end
        end
        html << pagination_gap(options) if start_number > last_page + 1
        page_range = [start_number, last_page + 1].max..end_number
        html.concat _as_pagination_window_links(current_page, page_range, url_options, options)
        html.concat _as_pagination_trailing_links(current_page, end_number, outer_window, url_options, options)
        safe_join html, ' '
      end

      def _as_pagination_window(current_page, inner_window)
        start_number = [current_page.number - inner_window, 1].max
        end_number = current_page.number + inner_window
        end_number = [end_number, current_page.pager.last.number].min unless current_page.pager.infinite?
        [start_number, end_number]
      end

      def _as_pagination_leading_links(current_page, url_options, options, outer_window)
        return [[], 0] if current_page.number == 1

        html = []
        last_page = 1
        last_page.upto([last_page + outer_window, current_page.number - 1].min) do |number|
          html << pagination_ajax_link(number, url_options, options)
          last_page = number
        end
        [html, last_page]
      end

      def _as_infinite_previous_pages(current_page, start_number, last_page)
        [20, 100].reverse_each.filter_map do |offset|
          page = current_page.number - offset
          page if page < start_number && page > last_page
        end
      end

      def _as_pagination_window_links(current_page, page_range, url_options, options)
        page_range.map do |number|
          if current_page.number == number
            pagination_active_page(number, url_options, options)
          else
            pagination_ajax_link(number, url_options, options)
          end
        end
      end

      def _as_pagination_trailing_links(current_page, end_number, outer_window, url_options, options)
        return _as_infinite_trailing_links(current_page, url_options, options) if current_page.pager.infinite?

        html = []
        html << pagination_gap(options) unless end_number >= current_page.pager.last.number - outer_window - 1
        first_page = [end_number + 1, current_page.pager.last.number - outer_window].max
        first_page.upto(current_page.pager.last.number) do |number|
          html << pagination_ajax_link(number, url_options, options)
        end
        html
      end

      def _as_infinite_trailing_links(current_page, url_options, options)
        [20, 100].flat_map do |offset|
          [pagination_gap(options), pagination_ajax_link(current_page.number + offset, url_options, options)]
        end
      end
      private :_as_pagination_window, :_as_pagination_leading_links, :_as_infinite_previous_pages,
              :_as_pagination_window_links, :_as_pagination_trailing_links, :_as_infinite_trailing_links
    end
  end
end
