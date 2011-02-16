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
      include ActiveScaffold::Helpers::CountryHelpers
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
        return false if column.association.reverse_for?(parent_record.class)

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

      # Provides list of javascripts to include with +javascript_include_tag+
      # You can use this with your javascripts like
      #   <%= javascript_include_tag :defaults, 'your_own_cool_script', active_scaffold_javascripts, :cache => true %>
      def active_scaffold_javascripts(frontend = :default)
        ActiveScaffold::Config::Core.javascripts(frontend).collect do |name|
          ActiveScaffold::Config::Core.asset_path(name, frontend)
        end
      end
      
      # Provides stylesheets to include with +stylesheet_link_tag+
      def active_scaffold_stylesheets(frontend = :default)
        [ActiveScaffold::Config::Core.asset_path("stylesheet.css", frontend)]
      end

      # Provides stylesheets for IE to include with +stylesheet_link_tag+ 
      def active_scaffold_ie_stylesheets(frontend = :default)
        [ActiveScaffold::Config::Core.asset_path("stylesheet-ie.css", frontend)]
      end

      # easy way to include ActiveScaffold assets
      def active_scaffold_includes(*args)
        frontend = args.first.is_a?(Symbol) ? args.shift : :default
        options = args.first.is_a?(Hash) ? args.shift : {}
        js = javascript_include_tag(*active_scaffold_javascripts(frontend).push(options))

        css = stylesheet_link_tag(*active_scaffold_stylesheets(frontend).push(options))
        options[:cache] += '_ie' if options[:cache].is_a? String
        options[:concat] += '_ie' if options[:concat].is_a? String
        ie_css = stylesheet_link_tag(*active_scaffold_ie_stylesheets(frontend).push(options))

        js + "\n" + css + "\n<!--[if IE]>".html_safe + ie_css + "<![endif]-->\n".html_safe
      end

      # a general-use loading indicator (the "stuff is happening, please wait" feedback)
      def loading_indicator_tag(options)
        image_tag "/images/active_scaffold/default/indicator.gif", :style => "visibility:hidden;", :id => loading_indicator_id(options), :alt => "loading indicator", :class => "loading-indicator"
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
        (!link.ignore_method.nil? and controller.try(link.ignore_method, *args)) || ((link.security_method_set? or controller.respond_to? link.security_method) and !controller.send(link.security_method, *args))
      end

      def render_action_link(link, url_options, record = nil, html_options = {})
        url_options = action_link_url_options(link, url_options, record)
        html_options = action_link_html_options(link, url_options, record, html_options)
        action_link_html(link, url_options, html_options)
      end

      def render_group_action_link(link, url_options, options, record = nil)
        if link.type == :member && !options[:authorized]
          action_link_html(link, nil, {:class => "disabled #{link.action}#{link.html_options[:class].blank? ? '' : (' ' + link.html_options[:class])}"})
        else
          render_action_link(link, url_options, record)
        end
      end
      
      def action_link_url_options(link, url_options, record, options = {})
        url_options = url_options.clone
        url_options[:action] = link.action
        url_options[:controller] = link.controller if link.controller
        url_options.delete(:search) if link.controller and link.controller.to_s != params[:controller]
        url_options.merge! link.parameters if link.parameters
        @link_record = record
        url_options.merge! self.instance_eval(&(link.dynamic_parameters)) if link.dynamic_parameters.is_a?(Proc)
        @link_record = nil
        url_options_for_nested_link(link.column, record, link, url_options, options) if link.nested_link?
        url_options_for_sti_link(link.column, record, link, url_options, options) unless record.nil? || active_scaffold_config.sti_children.nil?
        url_options[:_method] = link.method if !link.confirm? && link.inline? && link.method != :get
        url_options
      end
      
      def action_link_html_options(link, url_options, record, html_options)
        link_id = get_action_link_id(url_options, record, link.column)
        html_options.reverse_merge! link.html_options.merge(:class => link.action)

        # Needs to be in html_options to as the adding _method to the url is no longer supported by Rails        
        html_options[:method] = link.method if link.method != :get

        html_options['data-confirm'] = link.confirm(record.try(:to_label)) if link.confirm?
        html_options['data-position'] = link.position if link.position and link.inline?
        html_options[:class] += ' as_action' if link.inline?
        if link.popup?
          html_options['data-popup'] = true
          html_options[:target] = '_blank'
        end
        html_options[:id] = link_id
        html_options[:remote] = true unless link.page? || link.popup?
        if link.dhtml_confirm?
          html_options[:class] += ' as_action' if !link.inline?
          html_options[:page_link] = 'true' if !link.inline?
          html_options[:dhtml_confirm] = link.dhtml_confirm.value
          html_options[:onclick] = link.dhtml_confirm.onclick_function(controller, link_id)
        end
        html_options[:class] += " #{link.html_options[:class]}" unless link.html_options[:class].blank?
        html_options
      end

      def get_action_link_id(url_options, record = nil, column = nil)
        id = url_options[:id] || url_options[:parent_id]
        id = "#{column.association.name}-#{record.id}" if column && column.plural_association?
        if record.try(column.association.name.to_sym).present?
          id = "#{column.association.name}-#{record.send(column.association.name).id}"
        else
          id = "#{column.association.name}-#{record.id}" unless record.nil?
        end if column && column.singular_association?
        action_id = "#{id_from_controller(url_options[:controller]) + '-' if url_options[:parent_controller]}#{url_options[:action].to_s}"
        action_link_id(action_id, id)
      end
      
      def action_link_html(link, url, html_options)
        # issue 260, use url_options[:link] if it exists. This prevents DB data from being localized.
        label = url.delete(:link) if url.is_a?(Hash) 
        label ||= link.label
        if link.image.nil?
          html = link_to(label, url, html_options)
        else
          html = link_to(image_tag(link.image[:name] , :size => link.image[:size], :alt => label), url, html_options)
        end
        # if url is nil we would like to generate an anchor without href attribute
        url.nil? ? html.sub(/href=".*?"/, '') : html 
      end
      
      def url_options_for_nested_link(column, record, link, url_options, options = {})
        if column && column.association 
          url_options[:assoc_id] = url_options.delete(:id)
          url_options[:id] = record.send(column.association.name).id if column.singular_association? && record.send(column.association.name).present?
          link.eid = "#{controller_id.from(3)}_#{record.id}_#{column.association.name}" unless options.has_key?(:reuse_eid)
          url_options[:eid] = link.eid
        elsif link.parameters && link.parameters[:named_scope]
          url_options[:assoc_id] = url_options.delete(:id)
          link.eid = "#{controller_id.from(3)}_#{record.id}_#{link.parameters[:named_scope]}" unless options.has_key?(:reuse_eid)
          url_options[:eid] = link.eid
        end
      end

      def url_options_for_sti_link(column, record, link, url_options, options = {})
        #need to find out controller of current record type
        #and set parameters
        sti_controller_path = controller_path_for_activerecord(record.class)
        if sti_controller_path
          url_options[:controller] = sti_controller_path
          url_options[:parent_sti] = controller_path
        end
      end

      def column_class(column, column_value, record)
        classes = []
        classes << "#{column.name}-column"
        if column.css_class.is_a?(Proc)
          css_class = column.css_class.call(column_value, record)
          classes << css_class unless css_class.nil?
        else
          classes << column.css_class
        end unless column.css_class.nil?
         
        classes << 'empty' if column_empty? column_value
        classes << 'sorted' if active_scaffold_config.list.user.sorting.sorts_on?(column)
        classes << 'numeric' if column.column and [:decimal, :float, :integer].include?(column.column.type)
        classes.join(' ').rstrip
      end
      
      def column_heading_class(column, sorting)
        classes = []
        classes << "#{column.name}-column_heading"
        classes << "sorted #{sorting.direction_of(column).downcase}" if sorting.sorts_on? column
        classes << column.css_class unless column.css_class.nil? || column.css_class.is_a?(Proc)
        classes.join(' ')
      end

      def column_empty?(column_value)
        empty = column_value.nil?
        empty ||= column_value.empty? if column_value.respond_to? :empty?
        empty ||= ['&nbsp;', active_scaffold_config.list.empty_field_text].include? column_value if String === column_value
        return empty
      end

      def column_calculation(column)
        unless column.calculate.instance_of? Proc
          conditions = controller.send(:all_conditions)
          includes = active_scaffold_config.list.count_includes
          includes ||= controller.send(:active_scaffold_includes) unless conditions.nil?
          calculation = beginning_of_chain.calculate(column.calculate, column.name, :conditions => conditions,
           :joins => controller.send(:joins_for_collection), :include => includes)
        else
          column.calculate.call(@records)
        end
      end

      def render_column_calculation(column)
        calculation = column_calculation(column)
        override_formatter = "render_#{column.name}_#{column.calculate}"
        calculation = send(override_formatter, calculation) if respond_to? override_formatter

        "#{"#{as_(column.calculate)}: " unless column.calculate.is_a? Proc}#{format_column_value nil, column, calculation}"
      end

      def column_show_add_existing(column)
        (column.allow_add_existing and options_for_association_count(column.association) > 0)
      end

      def column_show_add_new(column, associated, record)
        value = column.plural_association? || (column.singular_association? and not associated.empty?)
        value = false unless record.class.authorized_for?(:crud_type => :create)
        value
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
