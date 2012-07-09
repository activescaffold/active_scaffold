module ActiveScaffold
  module Helpers
    # All extra helpers that should be included in the View.
    # Also a dumping ground for uncategorized helpers.
    module ViewHelpers
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
        begin
          controller = active_scaffold_controller_for(klass)
          controller.controller_path
        rescue ActiveScaffold::ControllerNotFound
          controller = nil
        end
      end

      # This is the template finder logic, keep it updated with however we find stuff in rails
      # currently this very similar to the logic in ActionBase::Base.render for options file
      def template_exists?(template_name, partial = false)
        lookup_context.exists? template_name, '', partial
      end

      def generate_temporary_id
        (Time.now.to_f*1000).to_i.to_s
      end

      # Turns [[label, value]] into <option> tags
      # Takes optional parameter of :include_blank
      def option_tags_for(select_options, options = {})
        select_options.insert(0,[as_(:_select_),nil]) if options[:include_blank]
        select_options.collect do |option|
          label, value = option[0], option[1]
          value.nil? ? "<option value="">#{label}</option>" : "<option value=\"#{value}\">#{label}</option>"
        end
      end

      # Should this column be displayed in the subform?
      def in_subform?(column, parent_record)
        return true unless column.association

        # Polymorphic associations can't appear because they *might* be the reverse association, and because you generally don't assign an association from the polymorphic side ... I think.
        return false if column.polymorphic_association?

        # A column shouldn't be in the subform if it's the reverse association to the parent
        return false if column.association.inverse_for?(parent_record.class)

        return true
      end

      def form_remote_upload_tag(url_for_options = {}, options = {})
        options[:target] = action_iframe_id(url_for_options)
        options[:multipart] ||= true
        options[:class] = "#{options[:class]} as_remote_upload".strip 
        output=""
        output << form_tag(url_for_options, options)
        (output << "<iframe id='#{action_iframe_id(url_for_options)}' name='#{action_iframe_id(url_for_options)}' style='display:none'></iframe>").html_safe
      end

      # a general-use loading indicator (the "stuff is happening, please wait" feedback)
      def loading_indicator_tag(options)
        image_tag "active_scaffold/indicator.gif", :style => "visibility:hidden;", :id => loading_indicator_id(options), :alt => "loading indicator", :class => "loading-indicator"
      end

      # Creates a javascript-based link that toggles the visibility of some element on the page.
      # By default, it toggles the visibility of the sibling after the one it's nested in. You may pass custom javascript logic in options[:of] to change that, though. For example, you could say :of => '$("my_div_id")'.
      # You may also flag whether the other element is visible by default or not, and the initial text will adjust accordingly.
      def link_to_visibility_toggle(id, options = {})
        options[:default_visible] = true if options[:default_visible].nil?
        options[:hide_label] = as_(:hide) 
        options[:show_label] = as_(:show)
        javascript_tag("ActiveScaffold.create_visibility_toggle('#{id}', #{options.to_json});")
      end

      def skip_action_link(link, *args)
        (!link.ignore_method.nil? && controller.respond_to?(link.ignore_method) && controller.send(link.ignore_method, *args)) || ((link.security_method_set? or controller.respond_to? link.security_method) and !controller.send(link.security_method, *args))
      end

      def render_action_link(link, record = nil, html_options = {})
        url = action_link_url(link, record)
        html_options = action_link_html_options(link, record, html_options)
        action_link_html(link, url, html_options, record)
      end

      def render_group_action_link(link, options, record = nil)
        if link.type == :member && !options[:authorized]
          action_link_html(link, nil, {:class => "disabled #{link.action}#{link.html_options[:class].blank? ? '' : (' ' + link.html_options[:class])}"}, record)
        else
          render_action_link(link, record)
        end
      end
      
      def action_link_url(link, record)
        url = if link.cached_url
          link.cached_url
        else
          url = url_for(action_link_url_options(link, record))
          link.cached_url = url unless link.dynamic_parameters.is_a?(Proc)
          url
        end
        
        url = record ? url.sub('--ID--', record.id.to_s) : url
        query_string, non_nested_query_string = query_string_for_action_links(link)
        if query_string || (!link.nested_link? && non_nested_query_string)
          url << (url.include?('?') ? '&' : '?')
          url << query_string if query_string
          url << non_nested_query_string if !link.nested_link? && non_nested_query_string
        end
        url
      end

      def query_string_for_action_links(link)
        if defined?(@query_string) && link.parameters.none? { |k, v| @query_string_params.include? k }
          return [@query_string, @non_nested_query_string]
        end
        keep = true
        @query_string_params = Set.new
        query_string_for_all = nil
        query_string_options = []
        non_nested_query_string_options = []
        
        params_for.except(:controller, :action, :id).each do |key, value|
          if link.parameters.include? key
            keep = false
            next
          end
          @query_string_params << key
          qs = "#{key}=#{value}"
          if key == :eid || conditions_from_params.include?(key) || (nested? && nested.constrained_fields.include?(key))
            non_nested_query_string_options << qs
          else
            query_string_options << qs
          end
        end
        
        query_string = URI.escape(query_string_options.join('&')) if query_string_options.present?
        if non_nested_query_string_options.present?
          non_nested_query_string = "#{'&' if query_string}#{URI.escape(non_nested_query_string_options.join('&'))}"
        end
        if keep
          @query_string = query_string
          @non_nested_query_string = non_nested_query_string
        end
        [query_string, non_nested_query_string]
      end
      
      def action_link_url_options(link, record)
        url_options = {:action => link.action}
        url_options[:id] = '--ID--' unless record.nil?
        url_options[:controller] = link.controller.to_s if link.controller
        url_options.merge! link.parameters if link.parameters
        if link.dynamic_parameters.is_a?(Proc)
          @link_record = record
          url_options.merge! self.instance_eval(&(link.dynamic_parameters)) 
          @link_record = nil
        end
        url_options_for_nested_link(link.column, record, link, url_options) if link.nested_link?
        url_options_for_sti_link(link.column, record, link, url_options) unless record.nil? || active_scaffold_config.sti_children.nil?
        url_options[:_method] = link.method if !link.confirm? && link.inline? && link.method != :get
        url_options
      end
      
      def action_link_html_options(link, record, html_options)
        link_id = get_action_link_id(link, record)
        html_options.reverse_merge! link.html_options.merge(:class => link.action.to_s)

        # Needs to be in html_options to as the adding _method to the url is no longer supported by Rails        
        html_options[:method] = link.method if link.method != :get

        html_options[:data] = {}
        html_options[:data][:confirm] = link.confirm(record.try(:to_label)) if link.confirm?
        if link.inline?
          html_options[:class] += ' as_action'
          html_options[:data][:position] = link.position if link.position
          html_options[:data][:action] = link.action
          html_options[:data][:'cancel-refresh'] = true if link.refresh_on_close
        end
        if link.popup?
          html_options[:data][:popup] = true
          html_options[:target] = '_blank'
        end
        html_options[:id] = link_id
        html_options[:remote] = true unless link.page? || link.popup?
        if link.dhtml_confirm?
          unless link.inline?
            html_options[:class] += ' as_action'
            html_options[:page_link] = 'true'
          end
          html_options[:dhtml_confirm] = link.dhtml_confirm.value
          html_options[:onclick] = link.dhtml_confirm.onclick_function(controller, link_id)
        end
        html_options[:class] += " #{link.html_options[:class]}" unless link.html_options[:class].blank?
        html_options
      end

      def get_action_link_id(link, record = nil, column = nil)
        column ||= link.column
        id = record ? record.id.to_s : (nested? ? nested.parent_id : '')
        if column && column.plural_association?
          id = "#{column.association.name}-#{record.id}"
        elsif column && column.singular_association?
          if record.try(column.association.name.to_sym).present?
            id = "#{column.association.name}-#{record.send(column.association.name).id}-#{record.id}"
          else
            id = "#{column.association.name}-#{record.id}" unless record.nil?
          end
        end
        action_id = "#{id_from_controller("#{link.controller}-") if params[:parent_controller]}#{link.action}"
        action_link_id(action_id, id)
      end
      
      def action_link_html(link, url, html_options, record)
        label = html_options.delete(:link)
        label ||= link.label
        label = image_tag(link.image[:name], :size => link.image[:size], :alt => label, :title => label) if link.image
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
          #url_options[:id] = record.send(column.association.name).id if column.singular_association? && record.send(column.association.name).present? FIXME on fixing singular nested links
        elsif link.parameters && link.parameters[:named_scope]
          url_options[:parent_scaffold] = controller_path
          url_options[active_scaffold_config.model.name.foreign_key.to_sym] = url_options.delete(:id)
        end
      end

      def url_options_for_sti_link(column, record, link, url_options)
        #need to find out controller of current record type
        #and set parameters
        # its quite difficult to detect an sti link
        # if link.column.nil? we are sure that it is nt an singular association inline autolink
        # howver that will not work if a sti parent is an singular association inline autolink
        if link.column.nil?
          sti_controller_path = controller_path_for_activerecord(record.class)
          if sti_controller_path
            url_options[:controller] = sti_controller_path
            url_options[:parent_sti] = controller_path
          end
        end
      end

      def list_row_class_method(record)
        return @_list_row_class_method if defined? @_list_row_class_method
        class_override_helper = :"#{clean_class_name(record.class.name)}_list_row_class"
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
          classes << 'sorted ' if active_scaffold_config.list.user.sorting.sorts_on?(column)
          classes << 'numeric ' if column.column and [:decimal, :float, :integer].include?(column.column.type)
          classes << column.css_class unless column.css_class.nil? || column.css_class.is_a?(Proc)
        end
        classes = "#{@_column_classes[column.name]} "
        classes << 'empty ' if column_empty? column_value
        classes << 'in_place_editor_field ' if inplace_edit?(record, column) or column.list_ui == :marked
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
        classes << " as_touch" if touch_device?
        classes
      end

      def column_empty?(column_value)
        empty = column_value.nil?
        empty ||= column_value.blank?
        empty ||= ['&nbsp;', active_scaffold_config.list.empty_field_text].include? column_value if String === column_value
        return empty
      end

      def column_calculation(column)
        unless column.calculate.instance_of? Proc
          calculate(column)
        else
          column.calculate.call(@records)
        end
      end

      def render_column_calculation(column)
        calculation = column_calculation(column)
        override_formatter = "render_#{column.name}_#{column.calculate.is_a?(Proc) ? :calculate : column.calculate}"
        calculation = send(override_formatter, calculation) if respond_to? override_formatter

        "#{"#{as_(column.calculate)}: " unless column.calculate.is_a? Proc}#{format_column_value nil, column, calculation}"
      end

      def column_show_add_existing(column)
        (column.allow_add_existing and options_for_association_count(column.association) > 0)
      end

      def column_show_add_new(column, associated, record)
        value = (column.plural_association? && !column.readonly_association?) || (column.singular_association? and not associated.empty?)
        value = false unless column.association.klass.authorized_for?(:crud_type => :create)
        value
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
        @_override_helpers ||= {}
        @_override_helpers[suffix] ||= {}
        return @_override_helpers[suffix][column.name] if @_override_helpers[suffix].include? column.name
        @_override_helpers[suffix][column.name] = begin
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
            highlight(msg, phrases, highlighter)
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
        count = objects.inject(0) {|sum, object| sum + object.errors.count }

        unless count.zero?
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

          header_message = if options.include?(:header_message)
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
          error_messages = if options[:list_type] == :br
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
        else
          ''
        end
      end
    end
  end
end
