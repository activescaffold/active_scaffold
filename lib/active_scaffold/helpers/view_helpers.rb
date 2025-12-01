# frozen_string_literal: true

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
      include ActiveScaffold::Helpers::TabsHelpers
      include ActiveScaffold::Helpers::SearchColumnHelpers
      include ActiveScaffold::Helpers::HumanConditionHelpers
      include ActiveScaffold::Helpers::FilterHelpers
      include ActiveScaffold::Helpers::FrameworkUiHelpers

      ##
      ## Delegates
      ##

      def active_scaffold_controller_for(klass)
        controller.class.active_scaffold_controller_for(klass)
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
        if @_view_paths
          restore_view_paths = lookup_context.view_paths
          lookup_context.view_paths = @_view_paths
        end
        (@_lookup_context || lookup_context).exists?(template_name, '', partial).tap do
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
        # it's call many times and we can cache same result
        @_loading_indicator_path ||= image_path('active_scaffold/indicator.gif')
        # it's call many times in long lists, image_tag is a bit slower
        tag.img(src: @_loading_indicator_path, style: 'visibility:hidden;', id: loading_indicator_id(options), alt: 'loading indicator', class: 'loading-indicator')
      end

      # Creates a javascript-based link that toggles the visibility of some element on the page.
      # By default, it toggles the visibility of the sibling after the one it's nested in.
      # You may also flag whether the other element is visible by default or not, and the initial text will adjust accordingly.
      def link_to_visibility_toggle(id, options = {})
        options[:hide_label] ||= as_(:hide)
        options[:show_label] ||= as_(:show_block)
        label = options[:default_visible].nil? || options[:default_visible] ? options[:hide_label] : options[:show_label]
        data = {show: options[:show_label], hide: options[:hide_label], toggable: id}
        link_to label, '#', data: data, style: 'display: none;', class: 'as-js-button visibility-toggle'
      end

      def list_row_class(record)
        class_override_helper = override_helper_per_model(:list_row_class, record.class)
        class_override_helper == :list_row_class ? '' : send(class_override_helper, record)
      end

      def list_row_attributes(tr_class, tr_id, data_refresh)
        {class: "record #{tr_class}", id: tr_id, data: {refresh: data_refresh}}
      end

      def column_attributes(column, record)
        method = override_helper column, 'column_attributes'
        return send(method, record) if method

        {}
      end

      def column_class(column, column_value, record)
        classes = ActiveScaffold::Registry.cache :column_classes, column.cache_key do
          classes = "#{column.name}-column "
          classes << 'sorted ' if active_scaffold_config.actions.include?(:list) && active_scaffold_config.list.user.sorting.sorts_on?(column)
          classes << 'numeric ' if column.number?
          classes << column.css_class << ' ' unless column.css_class.nil? || column.css_class.is_a?(Proc)
          classes
        end
        classes = classes.dup
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
        classes << 'skip-local-sorting' if column.skip_local_sorting?
        classes << column.css_class unless column.css_class.nil? || column.css_class.is_a?(Proc)
        classes
      end

      def as_main_div_class
        classes = "active-scaffold active-scaffold-#{controller_id}  #{id_from_controller params[:controller]}-view #{active_scaffold_config.theme}-theme"
        classes << ' as_touch' if touch_device?
        classes
      end

      def as_main_div_data
        params[:eid] ? {eid: id_from_controller(params[:eid])} : {}
      end

      def server_error_msg(content = nil, **attributes, &)
        as_element :server_error, content, **attributes, &
      end

      def column_empty?(column_value)
        @_empty_values ||= ['&nbsp;', empty_field_text].compact
        empty = column_value.nil?
        # column_value != false would force boolean to be cast to integer
        # when comparing to column_value of IPAddr class (PostgreSQL inet column type)
        empty ||= false != column_value && column_value.blank? # rubocop:disable Style/YodaCondition
        empty ||= @_empty_values.include? column_value
        empty
      end

      def empty_field_text(column = nil)
        return column.empty_field_text if column&.empty_field_text
        return @_empty_field_text if defined? @_empty_field_text

        @_empty_field_text = (active_scaffold_config.list.empty_field_text if active_scaffold_config.actions.include?(:list))
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

      def override_helper_per_model(method, model, cache_keys = nil)
        cache_keys ||= [method, model.name]
        ActiveScaffold::Registry.cache(*cache_keys) do
          model_names = [model.name]
          model_names << model.base_class.name if model.respond_to?(:base_class) && model.base_class != model
          method_with_class = model_names.find do |model_name|
            method_with_class = "#{clean_class_name(model_name)}_#{method}"
            break method_with_class if respond_to?(method_with_class)
          end
          method_with_class || (method if respond_to?(method))
        end
      end

      def override_helper(column, suffix)
        method = "#{clean_column_name(column.name)}_#{suffix}"
        override_helper_per_model(method, column.active_record_class, [suffix, column.cache_key])
      end

      def history_state
        if active_scaffold_config.store_user_settings
          state = {page: @page&.number}
          state[:search] = search_params if respond_to?(:search_params) && search_params.present?
          if active_scaffold_config.list.user.user_sorting?
            column, state[:sort_direction] = active_scaffold_config.list.user.sorting.first
            state[:sort] = column.name
          else
            state.merge sort: '', sort_direction: ''
          end
          state
        else
          {}
        end
      end

      def display_message(message)
        message = safe_join message, tag.br if message.is_a?(Array)
        if (highlights = active_scaffold_config.user.highlight_messages)
          message = highlights.inject(message) do |msg, (phrases, highlighter)|
            highlight(msg, phrases, highlighter || {})
          end
        end
        if (format = active_scaffold_config.user.timestamped_messages)
          format = :short if format == true
          messages = [content_tag(:div, l(Time.current, format: format), class: 'timestamp')]
          messages << content_tag(:div, message, class: 'message-content')
          message = safe_join messages, ' '
        end
        message
      end

      def active_scaffold_error_messages_for(*params)
        options = params.extract_options!.symbolize_keys
        options.reverse_merge!(container_tag: :div, list_type: :ul)

        objects = Array.wrap(options.delete(:object) || params).map do |object|
          object = instance_variable_get(:"@#{object}") unless object.respond_to?(:to_model)
          object = convert_to_model(object)

          options[:object_name] ||= object.class.model_name.human.downcase if object.class.respond_to?(:model_name)

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
              as_('errors.template.header', count: count, model: options[:object_name].to_s.tr('_', ' '))
            end

          message = options.include?(:message) ? options[:message] : as_('errors.template.body')

          error_messages = objects.sum([]) do |object|
            object.errors.full_messages.map do |msg|
              options[:list_type] == :br ? msg : content_tag(:li, msg)
            end
          end
          error_messages =
            if options[:list_type] == :br
              safe_join error_messages, tag.br
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

      def new_option_from_record(record)
        [record.to_label, record.id]
      end
    end
  end
end
