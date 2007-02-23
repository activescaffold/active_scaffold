module ActionView::Helpers
  module ActiveScaffoldListHelpers
    # checks whether the given action_link is allowed for the given record
    def record_is_allowed_for_link(record, link)
      return true unless record.respond_to? link.security_method
      current_user = controller.send(active_scaffold_config.current_user_method) rescue nil
      return true unless current_user #if there's no current_user, then don't check security
      return record.send(link.security_method, current_user)
    end

    def render_action_link(link, url_options)
      url_options = url_options.clone
      url_options[:action] = link.action
      url_options.merge! link.parameters if link.parameters

      html_options = {:class => link.action}
      html_options[:confirm] = link.confirm if link.confirm?
      html_options[:position] = link.position if link.position and link.inline?
      html_options[:id] = action_link_id(url_options)

      if link.page?
        link_to link.label, url_options, html_options
      elsif link.inline?
        html_options[:class] += ' action'
        link_to link.label, url_options, html_options
      end
    end

    def pagination_ajax_link(page_number, params)
      page_link = link_to_remote(page_number,
                { :url => params.merge(:page => page_number),
                  :before => "Element.show('#{loading_indicator_id(:action => :pagination)}');",
                  :update => active_scaffold_content_id },
                { :href => url_for(params.merge(:page => page_number)) })
    end

    def pagination_ajax_links(current_page, params)
      start_number = current_page.number - 2
      end_number = current_page.number + 2
      start_number = 1 if start_number <= 0
      end_number = current_page.pager.last.number if end_number > current_page.pager.last.number

      html = []
      html << pagination_ajax_link(1, params) unless current_page.number <= 3
      html << ".." unless current_page.number <= 4
      start_number.upto(end_number) do |num|
        if current_page.number == num
          html << num
        else
          html << pagination_ajax_link(num, params)
        end
      end
      html << ".." unless current_page.number >= current_page.pager.last.number - 3
      html << pagination_ajax_link(current_page.pager.last.number, params) unless current_page.number >= current_page.pager.last.number - 2
      html.join(' ')
    end

    def column_class(column, column_value)
      classes = []
      classes << column.name
      classes << column.css_class unless column.css_class.nil?
      classes << 'empty' if column_empty? column_value
      classes << 'sorted' if active_scaffold_config.list.user.sorting.sorts_on?(column)
      classes.join(' ')
    end

    ##
    ## Table cell formatting methods
    ##

    def render_column(record, column)
      value = record.send(column.name)

      if column.association.nil? or column_empty?(value)
        formatted_value = h(format_column(value))
      else
        case column.association.macro
          when :has_one, :belongs_to
            formatted_value = h(format_column(value.to_label))

          when :has_many, :has_and_belongs_to_many
            firsts = value.first(4).collect { |v| v.to_label }
            firsts[3] = '…' if firsts.length == 4
            formatted_value = h(format_column(firsts.join(', ')))
        end
      end

      # check for an override helper
      override_method_name = "#{column.name}_column"
      if respond_to? override_method_name
        override_method = self.method(override_method_name)
        formatted_value = override_method.arity < 2 ? override_method.call(formatted_value) : override_method.call(formatted_value, record)
      end

      formatted_value
    end

    def format_column(column_value)
      if column_empty?(column_value)
        active_scaffold_config.list.empty_field_text
      elsif column_value.instance_of? Time
        format_time(column_value)
      elsif column_value.instance_of? Date
        format_date(column_value)
      else
        column_value.to_s
      end
    end

    def format_time(time)
      time.strftime("%m/%d/%Y %I:%M %p")
    end

    def format_date(date)
      date.strftime("%m/%d/%Y")
    end

    def column_empty?(column_value)
      column_value.nil? || (column_value.empty? rescue false)
    end
  end
end