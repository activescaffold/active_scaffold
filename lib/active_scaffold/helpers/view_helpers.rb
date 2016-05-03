module ActiveScaffold
  module Helpers
    # All extra helpers that should be included in the View.
    # Also a dumping ground for uncategorized helpers.
    module ViewHelpers
      NESTED_PARAMS = [:eid, :association, :parent_scaffold]
      include ActiveScaffold::Helpers::IdHelpers
      include ActiveScaffold::Helpers::AssociationHelpers
      include ActiveScaffold::Helpers::PaginationHelpers
      include ActiveScaffold::Helpers::ListColumnHelpers
      include ActiveScaffold::Helpers::ShowColumnHelpers
      include ActiveScaffold::Helpers::FormColumnHelpers
      include ActiveScaffold::Helpers::SearchColumnHelpers
      include ActiveScaffold::Helpers::HumanConditionHelpers

      ##
      ## Delegates
      ##

      # access to the configuration variable
      def active_scaffold_config
        controller.class.active_scaffold_config
      end

      def active_scaffold_config_for(*args)
        controller.class.active_scaffold_config_for(*args)
      end

      def active_scaffold_controller_for(*args)
        controller.class.active_scaffold_controller_for(*args)
      end

      ##
      ## Uncategorized
      ##

      def controller_path_for_activerecord(klass)
        controller = active_scaffold_controller_for(klass)
        controller.controller_path
      rescue ActiveScaffold::ControllerNotFound
        nil
      end

      # This is the template finder logic, keep it updated with however we find stuff in rails
      # currently this very similar to the logic in ActionBase::Base.render for options file
      def template_exists?(template_name, partial = false)
        lookup_context.exists? template_name, '', partial
      end

      # Turns [[label, value]] into <option> tags
      # Takes optional parameter of :include_blank
      def option_tags_for(select_options, options = {})
        select_options.insert(0, [as_(:_select_), nil]) if options[:include_blank]
        select_options.collect do |option|
          label, value = option[0], option[1]
          value.nil? ? '<option value='">#{label}</option>" : "<option value=\"#{value}\">#{label}</option>"
        end
      end

      def form_remote_upload_tag(url_for_options = {}, options = {})
        options[:target] = action_iframe_id(url_for_options)
        options[:multipart] ||= true
        options[:class] = "#{options[:class]} as_remote_upload".strip
        output = ''
        output << form_tag(url_for_options, options)
        (output << "<iframe id='#{action_iframe_id(url_for_options)}' name='#{action_iframe_id(url_for_options)}' style='display:none'></iframe>").html_safe
      end

      # a general-use loading indicator (the "stuff is happening, please wait" feedback)
      def loading_indicator_tag(options)
        image_tag 'active_scaffold/indicator.gif', :style => 'visibility:hidden;', :id => loading_indicator_id(options), :alt => 'loading indicator', :class => 'loading-indicator'
      end

      # Creates a javascript-based link that toggles the visibility of some element on the page.
      # By default, it toggles the visibility of the sibling after the one it's nested in. You may pass custom javascript logic in options[:of] to change that, though. For example, you could say :of => '$("my_div_id")'.
      # You may also flag whether the other element is visible by default or not, and the initial text will adjust accordingly.
      def link_to_visibility_toggle(id, options = {})
        options[:default_visible] = true if options[:default_visible].nil?
        options[:hide_label] ||= as_(:hide)
        options[:show_label] ||= as_(:show_block)
        link_to options[:default_visible] ? options[:hide_label] : options[:show_label], '#', :data => {:show => options[:show_label], :hide => options[:hide_label], :toggable => id}, :style => 'display: none;', :class => 'as-js-button visibility-toggle'
      end

      def skip_action_link?(link, *args)
        !link.ignore_method.nil? && controller.respond_to?(link.ignore_method, true) && controller.send(link.ignore_method, *args)
      end

      def action_link_authorized?(link, *args)
        if link.security_method_set? || controller.respond_to?(link.security_method, true)
          controller.send(link.security_method, *args)
        else
          args.empty? ? true : args.first.authorized_for?(:crud_type => link.crud_type, :action => link.action)
        end
      end

      def display_dynamic_action_group(action_link, links, record_or_ul_options = nil, ul_options = nil)
        ul_options = record_or_ul_options if ul_options.nil? && record_or_ul_options.is_a?(Hash)
        record = record_or_ul_options unless record_or_ul_options.is_a?(Hash)
        html = content_tag :ul, ul_options do
          links.map { |link| content_tag :li, link }.join('').html_safe
        end
        raw "ActiveScaffold.display_dynamic_action_group('#{get_action_link_id action_link, record}', '#{escape_javascript html}');"
      end

      def display_action_links(action_links, record, options, &block)
        options[:level_0_tag] ||= nil
        options[:options_level_0_tag] ||= nil
        options[:level] ||= 0
        options[:first_action] = true
        output = ActiveSupport::SafeBuffer.new

        action_links.each(:reverse => options.delete(:reverse), :groups => true) do |link|
          if link.is_a? ActiveScaffold::DataStructures::ActionLinks
            unless link.empty?
              options[:level] += 1
              content = display_action_links(link, record, options, &block)
              options[:level] -= 1
              if content.present?
                output << display_action_link(link, content, record, options)
                options[:first_action] = false
              end
            end
          elsif !skip_action_link?(link, *Array(options[:for]))
            authorized = action_link_authorized?(link, *Array(options[:for]))
            next if !authorized && options[:skip_unauthorized]
            output << display_action_link(link, nil, record, options.merge(:authorized => authorized))
            options[:first_action] = false
          end
        end
        output
      end

      def display_action_link(link, content, record, options)
        if content
          html_classes = hover_via_click? ? 'hover_click ' : ''
          if options[:level] == 0
            html_classes << 'action_group'
            group_tag = :div
          else
            html_classes << 'top' if options[:first_action]
            group_tag = :li
          end
          content = content_tag(group_tag, :class => (html_classes if html_classes.present?), :onclick => ('' if hover_via_click?)) do
            content_tag(:div, as_(link.label), :class => link.name.to_s.downcase) << content_tag(:ul, content)
          end
        else
          content = render_action_link(link, record, options)
          content = content_tag(:li, content, :class => ('top' if options[:first_action])) unless options[:level] == 0
        end
        content = content_tag(options[:level_0_tag], content, options[:options_level_0_tag]) if options[:level] == 0 && options[:level_0_tag]
        content
      end

      def render_action_link(link, record = nil, options = {})
        if link.action.nil? || link.column.try(:polymorphic_association?)
          link = action_link_to_inline_form(link, record) if link.column.try(:association)
          options[:authorized] = false if link.action.nil? || link.controller.nil?
          options.delete :link if link.crud_type == :create
        end
        if link.action.nil? || (link.type == :member && options.key?(:authorized) && !options[:authorized])
          action_link_html(link, nil, {:link => action_link_text(link, options), :class => "disabled #{link.action}#{" #{link.html_options[:class]}" unless link.html_options[:class].blank?}"}, record)
        else
          url = action_link_url(link, record)
          html_options = action_link_html_options(link, record, options)
          action_link_html(link, url, html_options, record)
        end
      end

      # setup the action link to inline form
      def action_link_to_inline_form(link, record)
        link = link.clone
        associated = record.send(link.column.association.name)
        if link.column.polymorphic_association?
          link.controller = controller_path_for_activerecord(associated.class)
          return link if link.controller.nil?
        end
        link = configure_column_link(link, record, associated) if link.action.nil?
        link
      end

      def configure_column_link(link, record, associated, actions = nil)
        actions ||= link.column.actions_for_association_links
        if column_empty?(associated) # if association is empty, we only can link to create form
          if actions.include?(:new)
            link.action = 'new'
            link.crud_type = :create
            link.label ||= as_(:create_new)
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

        unless column_link_authorized?(link, link.column, record, associated)
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
            if column.plural_association? || (associated.respond_to?(:blank?) && associated.blank?)
              column.association.klass
            else
              associated
            end
          authorized = associated_for_authorized.authorized_for?(:crud_type => link.crud_type)
          authorized &&= record.authorized_for?(:crud_type => :update, :column => column.name) if link.crud_type == :create
          authorized
        else
          action_link_authorized?(link, record)
        end
      end

      def is_sti_record?(record)
        model = active_scaffold_config.model
        record && model.columns_hash.include?(model.inheritance_column) &&
          record[model.inheritance_column].present? && !record.instance_of?(model)
      end

      def cache_action_link_url?(link, record)
        active_scaffold_config.cache_action_link_urls && link.type == :member && !link.dynamic_parameters.is_a?(Proc) && !is_sti_record?(record)
      end

      def cached_action_link_url(link, record)
        @action_links_urls ||= {}
        @action_links_urls[link.name_to_cache] || begin
          url_options = cached_action_link_url_options(link, record)
          if cache_action_link_url?(link, record)
            @action_links_urls[link.name_to_cache] = url_for(url_options)
          else
            url_for(params_for(url_options))
          end
        end
      end

      def replace_id_params_in_action_link_url(link, record, url)
        url = record ? url.sub('--ID--', record.to_param.to_s) : url.clone
        if link.column.try(:singular_association?)
          child_id = record.send(link.column.association.name).try(:to_param)
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
        nested_params = (!link.nested_link? && non_nested_query_string)
        if query_string || nested_params
          url << (url.include?('?') ? '&' : '?')
          url << query_string if query_string
          url << non_nested_query_string if nested_params
        end
        url
      end

      def action_link_url(link, record)
        url = replace_id_params_in_action_link_url(link, record, cached_action_link_url(link, record))
        url = add_query_string_to_cached_url(link, url) if @action_links_urls[link.name_to_cache]
        url
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
          if NESTED_PARAMS.include?(key) || conditions_from_params.include?(key) || (nested? && nested.param_name == key)
            non_nested_query_string_options[key] = value
          else
            query_string_options[key] = value
          end
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
        active_scaffold_config.cache_action_link_urls && (link.type == :collection || !link.dynamic_parameters.is_a?(Proc)) && !is_sti_record?(record)
      end

      def cached_action_link_url_options(link, record)
        @action_links_url_options ||= {}
        @action_links_url_options[link.name_to_cache] || begin
          options = action_link_url_options(link, record)
          if cache_action_link_url_options?(link, record)
            @action_links_url_options[link.name_to_cache] = options
          end
          options
        end
      end

      def action_link_url_options(link, record)
        url_options = {:action => link.action}
        url_options[:id] = '--ID--' unless record.nil?
        url_options[:controller] = link.controller.to_s if link.controller
        url_options.merge! link.parameters if link.parameters
        if link.dynamic_parameters.is_a?(Proc)
          if record.nil?
            url_options.merge! instance_exec &link.dynamic_parameters
          else
            url_options.merge! instance_exec record, &link.dynamic_parameters
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

      def action_link_text(link, options)
        text = image_tag(link.image[:name], :size => link.image[:size], :alt => options[:link] || link.label, :title => options[:link] || link.label) if link.image
        text || options[:link]
      end

      def replaced_action_link_url_options(link, record)
        url = cached_action_link_url_options(link, record)
        url[:controller] ||= params[:controller]
        missing_options, url_options = url.partition { |_, v| v.nil? }
        replacements = {}
        replacements['--ID--'] = record.id.to_s if record
        if link.column.try(:singular_association?)
          replacements['--CHILD_ID--'] = record.send(link.column.association.name).try(:id).to_s
        elsif nested?
          replacements['--CHILD_ID--'] = params[nested.param_name].to_s
        end
        url_options.collect! do |k, v|
          [k.to_s, replacements[v] || v]
        end
        [missing_options, url_options]
      end

      def action_link_selected?(link, record)
        missing_options, url_options = replaced_action_link_url_options(link, record)
        (url_options - params.to_a).blank? && missing_options.all? { |k, _| params[k].nil? }
      end

      def action_link_html_options(link, record, options)
        link_id = get_action_link_id(link, record)
        html_options = link.html_options.merge(:class => [link.html_options[:class], link.action.to_s].compact.join(' '))
        html_options[:link] = action_link_text(link, options)

        # Needs to be in html_options to as the adding _method to the url is no longer supported by Rails
        html_options[:method] = link.method if link.method != :get

        html_options[:data] ||= {}
        html_options[:data][:confirm] = link.confirm(h(record.try(:to_label))) if link.confirm?
        if link.inline?
          html_options[:class] << ' as_action'
          html_options[:data][:position] = link.position if link.position
          html_options[:data][:action] = link.action
          html_options[:data][:cancel_refresh] = true if link.refresh_on_close
          html_options[:data][:keep_open] = true if link.keep_open?
        end

        if link.toggle
          html_options[:class] << ' toggle'
          html_options[:class] << ' active' if action_link_selected?(link, record)
        end

        html_options[:target] = '_blank' if link.popup?
        html_options[:id] = link_id
        html_options[:remote] = true unless link.page? || link.popup?
        if link.dhtml_confirm?
          unless link.inline?
            html_options[:class] << ' as_action'
            html_options[:page_link] = 'true'
          end
          html_options[:dhtml_confirm] = link.dhtml_confirm.value
          html_options[:onclick] = link.dhtml_confirm.onclick_function(controller, link_id)
        end
        html_options
      end

      def get_action_link_id(link, record = nil, column = nil)
        column ||= link.column
        if column && column.plural_association?
          id = "#{column.association.name}-#{record.id}"
        elsif column && column.singular_association?
          if record.try(column.association.name.to_sym).present?
            id = "#{column.association.name}-#{record.send(column.association.name).id}-#{record.id}"
          else
            id = "#{column.association.name}-#{record.id}" unless record.nil?
          end
        end
        id ||= record.try(:id) || (nested? ? nested_parent_id : '')
        action_id = "#{id_from_controller("#{link.controller}-") if params[:parent_controller] || (link.controller && link.controller != controller.controller_path)}#{link.action}"
        action_link_id(action_id, id)
      end

      def action_link_html(link, url, html_options, record)
        label = html_options.delete(:link)
        label ||= link.label
        if url.nil?
          content_tag(:a, label, html_options)
        else
          link_to(label, url, html_options)
        end
      end

      def url_options_for_nested_link(column, record, link, url_options)
        if column && column.association
          url_options[:parent_scaffold] = controller_path
          url_options[column.association.active_record.name.foreign_key.to_sym] = url_options.delete(:id)
          if column.singular_association? && url_options[:action].to_sym != :index
            url_options[:id] = '--CHILD_ID--'
          else
            url_options[:id] = nil
          end
        elsif link.parameters && link.parameters[:named_scope]
          url_options[:parent_scaffold] = controller_path
          url_options[active_scaffold_config.model.name.foreign_key.to_sym] = url_options.delete(:id)
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

      def list_row_class_method(record)
        return @_list_row_class_method if defined? @_list_row_class_method
        class_override_helper = "#{clean_class_name(record.class.name)}_list_row_class"
        @_list_row_class_method = (class_override_helper if respond_to?(class_override_helper))
      end

      def list_row_class(record)
        class_override_helper = list_row_class_method(record)
        class_override_helper ? send(class_override_helper, record) : ''
      end

      def column_attributes(column, record)
        method = override_helper column, 'column_attributes'
        return send(method, record) if method
        {}
      end

      def column_class(column, column_value, record)
        @_column_classes ||= {}
        @_column_classes[column.name] ||= begin
          classes = "#{column.name}-column "
          classes << 'sorted ' if active_scaffold_config.actions.include?(:list) && active_scaffold_config.list.user.sorting.sorts_on?(column)
          classes << 'numeric ' if column.number?
          classes << column.css_class unless column.css_class.nil? || column.css_class.is_a?(Proc)
        end
        classes = "#{@_column_classes[column.name]} "
        classes << 'empty ' if column_empty? column_value
        classes << 'in_place_editor_field ' if inplace_edit?(record, column) || column.list_ui == :marked
        if column.css_class.is_a?(Proc)
          css_class = column.css_class.call(column_value, record)
          classes << css_class unless css_class.nil?
        end
        classes
      end

      def column_heading_class(column, sorting)
        classes = "#{column.name}-column_heading "
        classes << "sorted #{sorting.direction_of(column).downcase} " if sorting.sorts_on? column
        classes << column.css_class unless column.css_class.nil? || column.css_class.is_a?(Proc)
        classes
      end

      def as_main_div_class
        classes = "active-scaffold active-scaffold-#{controller_id}  #{id_from_controller params[:controller]}-view #{active_scaffold_config.theme}-theme"
        classes << ' as_touch' if touch_device?
        classes
      end

      def column_empty?(column_value)
        empty = column_value.nil?
        empty ||= false != column_value && column_value.blank?
        empty ||= ['&nbsp;', empty_field_text].include? column_value if column_value.is_a? String
        empty
      end

      def empty_field_text
        active_scaffold_config.list.empty_field_text if active_scaffold_config.actions.include?(:list)
      end

      def column_calculation(column)
        if column.calculate.instance_of? Proc
          column.calculate.call(@records)
        else
          calculate_query.calculate(column.calculate, column.name)
        end
      end

      def render_column_calculation(column)
        calculation = column_calculation(column)
        override_formatter = "render_#{column.name}_#{column.calculate.is_a?(Proc) ? :calculate : column.calculate}"
        calculation = send(override_formatter, calculation) if respond_to? override_formatter
        format_column_calculation(column, calculation)
      end

      def format_column_calculation(column, calculation)
        "#{"#{as_(column.calculate)}: " unless column.calculate.is_a? Proc}#{format_column_value nil, column, calculation}"
      end
      
      def as_slider(options)
        content_tag(:span, '', class: 'as-slider', data: {slider: options})
      end

      def clean_column_name(name)
        name.to_s.gsub('?', '')
      end

      def clean_class_name(name)
        name.underscore.gsub('/', '_')
      end

      # the naming convention for overriding with helpers
      def override_helper_name(column, suffix, class_prefix = false)
        "#{clean_class_name(column.active_record_class.name) + '_' if class_prefix}#{clean_column_name(column.name)}_#{suffix}"
      end

      def override_helper(column, suffix)
        hash = @_override_helpers ||= {}
        hash = hash[suffix] ||= {}
        hash = hash[column.active_record_class.name] ||= {}
        return hash[column.name] if hash.include? column.name
        hash[column.name] = begin
          method_with_class = override_helper_name(column, suffix, true)
          if respond_to?(method_with_class)
            method_with_class
          else
            method = override_helper_name(column, suffix)
            method if respond_to?(method)
          end
        end
      end

      def display_message(message)
        if (highlights = active_scaffold_config.highlight_messages)
          message = highlights.inject(message) do |msg, (phrases, highlighter)|
            highlight(msg, phrases, highlighter || {})
          end
        end
        if (format = active_scaffold_config.timestamped_messages)
          format = :short if format == true
          message = "#{content_tag :div, l(Time.current, :format => format), :class => 'timestamp'} #{content_tag :div, message, :class => 'message-content'}".html_safe
        end
        message
      end

      def active_scaffold_error_messages_for(*params)
        options = params.extract_options!.symbolize_keys
        options.reverse_merge!(:container_tag => :div, :list_type => :ul)

        objects = Array.wrap(options.delete(:object) || params).map do |object|
          object = instance_variable_get("@#{object}") unless object.respond_to?(:to_model)
          object = convert_to_model(object)

          if object.class.respond_to?(:model_name)
            options[:object_name] ||= object.class.model_name.human.downcase
          end

          object
        end

        objects.compact!
        count = objects.inject(0) { |sum, object| sum + object.errors.count }

        if count.zero?
          ''
        else
          html = {}
          [:id, :class].each do |key|
            if options.include?(key)
              value = options[key]
              html[key] = value unless value.blank?
            else
              html[key] = 'errorExplanation'
            end
          end
          options[:object_name] ||= params.first

          header_message =
            if options.include?(:header_message)
              options[:header_message]
            else
              as_('errors.template.header', :count => count, :model => options[:object_name].to_s.gsub('_', ' '))
            end

          message = options.include?(:message) ? options[:message] : as_('errors.template.body')

          error_messages = objects.sum do |object|
            object.errors.full_messages.map do |msg|
              options[:list_type] != :br ? content_tag(:li, msg) : msg
            end
          end
          error_messages =
            if options[:list_type] == :br
              error_messages.join('<br/>').html_safe
            else
              content_tag(options[:list_type], error_messages.join.html_safe)
            end

          contents = []
          contents << content_tag(options[:header_tag] || :h2, header_message) unless header_message.blank?
          contents << content_tag(:p, message) unless message.blank?
          contents << error_messages
          contents = contents.join.html_safe
          options[:container_tag] ? content_tag(options[:container_tag], contents, html) : contents
        end
      end
    end
  end
end
