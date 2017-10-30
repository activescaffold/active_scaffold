module ActiveScaffold
  module Helpers
    # All extra helpers that should be included in the View.
    # Also a dumping ground for uncategorized helpers.
    module ViewHelpers
      include ActiveScaffold::Helpers::IdHelpers
      include ActiveScaffold::Helpers::ActionLinkHelpers
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
        restore_view_paths, lookup_context.view_paths = lookup_context.view_paths, @_view_paths if @_view_paths
        lookup_context.exists?(template_name, '', partial).tap do
          lookup_context.view_paths = restore_view_paths if @_view_paths
        end
      end

      def form_remote_upload_tag(url_for_options = {}, options = {})
        options[:target] = action_iframe_id(url_for_options)
        options[:multipart] ||= true
        options[:class] = "#{options[:class]} as_remote_upload".strip
        output = []
        output << form_tag(url_for_options, options)
        output << content_tag(:iframe, '', id: action_iframe_id(url_for_options), name: action_iframe_id(url_for_options), style: 'display:none')
        safe_join output
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
          classes
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
        # column_value != false would force boolean to be cast to integer
        # when comparing to column_value of IPAddr class (PostgreSQL inet column type)
        # rubocop:disable Style/YodaCondition
        empty ||= false != column_value && column_value.blank?
        empty ||= ['&nbsp;', empty_field_text].include? column_value if column_value.is_a? String
        empty
      end

      def empty_field_text
        active_scaffold_config.list.empty_field_text if active_scaffold_config.actions.include?(:list)
      end

      def as_slider(options)
        content_tag(:span, '', class: 'as-slider', data: {slider: options})
      end

      def clean_column_name(name)
        name.to_s.delete('?')
      end

      def clean_class_name(name)
        name.underscore.tr('/', '_')
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

      def history_state
        if active_scaffold_config.store_user_settings
          state = {page: @page.try(:number)}
          if active_scaffold_config.list.user.sorting.size == 1
            column, state[:sort_direction] = active_scaffold_config.list.user.sorting.first
            state[:sort] = column.name
          end
          state
        else
          {}
        end
      end

      def display_message(message)
        message = safe_join message, tag(:br) if message.is_a?(Array)
        if (highlights = active_scaffold_config.highlight_messages)
          message = highlights.inject(message) do |msg, (phrases, highlighter)|
            highlight(msg, phrases, highlighter || {})
          end
        end
        if (format = active_scaffold_config.timestamped_messages)
          format = :short if format == true
          messages = [content_tag(:div, l(Time.current, :format => format), :class => 'timestamp')]
          messages << content_tag(:div, message, :class => 'message-content')
          message = safe_join messages, ' '
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
          %i[id class].each do |key|
            if options.include?(key)
              value = options[key]
              html[key] = value if value.present?
            else
              html[key] = 'errorExplanation'
            end
          end
          options[:object_name] ||= params.first

          header_message =
            if options.include?(:header_message)
              options[:header_message]
            else
              as_('errors.template.header', :count => count, :model => options[:object_name].to_s.tr('_', ' '))
            end

          message = options.include?(:message) ? options[:message] : as_('errors.template.body')

          error_messages = objects.sum do |object|
            object.errors.full_messages.map do |msg|
              options[:list_type] != :br ? content_tag(:li, msg) : msg
            end
          end
          error_messages =
            if options[:list_type] == :br
              safe_join error_messages, tag(:br)
            else
              content_tag options[:list_type], safe_join(error_messages)
            end

          contents = []
          contents << content_tag(options[:header_tag] || :h2, header_message) if header_message.present?
          contents << content_tag(:p, message) if message.present?
          contents << error_messages
          contents = safe_join(contents)
          options[:container_tag] ? content_tag(options[:container_tag], contents, html) : contents
        end
      end
    end
  end
end
