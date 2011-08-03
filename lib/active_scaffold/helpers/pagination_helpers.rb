module ActiveScaffold
  module Helpers
    module PaginationHelpers
      def pagination_ajax_link(page_number, url_options, options)
        link_to page_number, url_options.merge(:page => page_number), options.merge(:class => "as_paginate")
      end

      def pagination_ajax_links(current_page, url_options, options, window_size)
        start_number = current_page.number - window_size
        end_number = current_page.number + window_size
        start_number = 1 if start_number <= 0
        if current_page.pager.infinite?
          offsets = [20, 100]
        else
          end_number = current_page.pager.last.number if end_number > current_page.pager.last.number
        end

        html = []
        unless start_number == 1
          last_page = 1
          html << pagination_ajax_link(last_page, url_options, options)
          if current_page.pager.infinite?
            offsets.reverse.each do |offset|
              page = current_page.number - offset
              if page < start_number && page > 1
                html << '..' if page > last_page + 1
                html << pagination_ajax_link(page, params)
                last_page = page
              end
            end
          end
          html << ".." if start_number > last_page + 1
        end

        start_number.upto(end_number) do |num|
          if current_page.number == num
            html << content_tag(:span, num.to_s, {:class => "as_paginate current"})
          else
            html << pagination_ajax_link(num, url_options, options)
          end
        end

        if current_page.pager.infinite?
          offsets.each do |offset|
            html << '..' << pagination_ajax_link(current_page.number + offset, url_options, options)
          end
        else
          html << ".." unless end_number >= current_page.pager.last.number - 1
          html << pagination_ajax_link(current_page.pager.last.number, url_options, options) unless end_number == current_page.pager.last.number
        end
        html.join(' ').html_safe
      end
    end
  end
end
