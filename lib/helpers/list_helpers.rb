module ActionView::Helpers
  module ActiveScaffoldListHelpers
    def render_action_link(link, url_options)
      url_options = url_options.clone
      url_options[:action] = link.action
      url_options.merge! link.parameters if link.parameters

      # NOTE this is in url_options instead of html_options on purpose. the reason is that the client-side
      # action link javascript needs to submit the proper method, but the normal html_options[:method]
      # argument leaves no way to extract the proper method from the rendered tag.
      url_options[:_method] = link.method

      html_options = {:class => link.action}
      html_options[:confirm] = link.confirm if link.confirm?
      html_options[:position] = link.position if link.position and link.inline?
      html_options[:class] += ' action' if link.inline?
      html_options[:popup] = true if link.popup?

      link_to link.label, url_options, html_options
    end

    def pagination_ajax_link(page_number, params)
      page_link = link_to_remote(page_number,
                { :url => params.merge(:page => page_number),
                  :before => "Element.show('#{loading_indicator_id(:action => :pagination)}');",
                  :update => active_scaffold_content_id,
                  :failure => "ActiveScaffold.report_500_response('#{active_scaffold_id}')",
                  :method => :get },
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
      classes << 'numeric' if [:decimal, :float, :integer].include?(column.column.type)
      classes.join(' ')
    end

    ##
    ## Table cell formatting methods
    ##

    def render_column(record, column)
      # check for an override helper
      if column_override? column
        # we only pass the record as the argument. we previously also passed the formatted_value,
        # but mike perham pointed out that prohibited the usage of overrides to improve on the
        # performance of our default formatting. see issue #138.
        send(column_override(column), record)
      else
        value = record.send(column.name)
        if column.association.nil? or column_empty?(value)
          formatted_value = clean_column_value(format_column(value))
        else
          case column.association.macro
            when :has_one, :belongs_to
              formatted_value = clean_column_value(format_column(value.to_label))

            when :has_many, :has_and_belongs_to_many
              firsts = value.first(4).collect { |v| v.to_label }
              firsts[3] = '…' if firsts.length == 4
              formatted_value = clean_column_value(format_column(firsts.join(', ')))
          end
        end

        formatted_value
      end
    end

    # There are two basic ways to clean a column's value: h() and sanitize(). The latter is useful
    # when the column contains *valid* html data, and you want to just disable any scripting. People
    # can always use field overrides to clean data one way or the other, but having this override
    # lets people decide which way it should happen by default.
    #
    # Why is it not a configuration option? Because it seems like a somewhat rare request. But it
    # could eventually be an option in config.list (and config.show, I guess).
    def clean_column_value(v)
      h(v)
    end

    def column_override(column)
      "#{column.name}_column"
    end

    def column_override?(column)
      respond_to?(column_override(column))
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
      format = ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS[:default] || "%m/%d/%Y %I:%M %p"
      time.strftime(format)
    end

    def format_date(date)
      format = ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS[:default] || "%m/%d/%Y"
      date.strftime(format)
    end

    def column_empty?(column_value)
      column_value.nil? || (column_value.empty? rescue false)
    end

    def column_calculation(column)
      calculation = active_scaffold_config.model.calculate(column.calculate, column.name, :conditions => controller.send(:all_conditions))
    end
  end
end