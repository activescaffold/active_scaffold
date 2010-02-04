module ActiveScaffold
  module Helpers
    module PaginationHelpers
      def pagination_ajax_link(page_number, params)
        url = url_for params.merge(:page => page_number)
        page_link = link_to_remote(page_number,
                  { :url => url,
                    :before => "addActiveScaffoldPageToHistory('#{url}', '#{controller_id}');",
                    :after => "$('#{loading_indicator_id(:action => :pagination)}').style.visibility = 'visible';",
                    :complete => "$('#{loading_indicator_id(:action => :pagination)}').style.visibility = 'hidden';",
                    :update => active_scaffold_content_id,
                    :failure => "ActiveScaffold.report_500_response('#{active_scaffold_id}')",
                    :method => :get },
                  { :href => url_for(params.merge(:page => page_number)) })
      end

      def pagination_ajax_links(current_page, params, window_size)
        start_number = current_page.number - window_size
        end_number = current_page.number + window_size
        start_number = 1 if start_number <= 0
        end_number = current_page.pager.last.number if end_number > current_page.pager.last.number

        html = []
        html << pagination_ajax_link(1, params) unless start_number == 1
        html << ".." unless start_number <= 2
        start_number.upto(end_number) do |num|
          if current_page.number == num
            html << num
          else
            html << pagination_ajax_link(num, params)
          end
        end
        html << ".." unless end_number >= current_page.pager.last.number - 1
        html << pagination_ajax_link(current_page.pager.last.number, params) unless end_number == current_page.pager.last.number
        html.join(' ')
      end
    end
  end
end
