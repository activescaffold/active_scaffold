# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a List Column
    module ListColumnHelpers
      def list_record_view
        'list_record'
      end

      def get_column_value(record, column)
        record = record.send(column.delegated_association.name) if column.delegated_association
        if record
          method, list_ui = get_column_method(record, column)
          value =
            if list_ui
              send(method, record, column, ui_options: column.list_ui_options || column.options)
            else
              send(method, record, column)
            end
        else
          value = nil
        end
        value = '&nbsp;'.html_safe if value.nil? || value.blank? # fix for IE 6
        value
      rescue StandardError => e
        message = "on the ActiveScaffold column = :#{column.name} in #{controller.class}, record: #{record.inspect}"
        Rails.logger.error "#{e.class.name}: #{e.message} -- #{message}"
        raise e.class, "#{e.message} -- #{message}", e.backtrace
      end

      def get_column_method(record, column)
        # check for an override helper
        ActiveScaffold::Registry.cache :column_methods, column.cache_key do
          if (method = column_override(column))
            # we only pass the record as the argument. we previously also passed the formatted_value,
            # but mike perham pointed out that prohibited the usage of overrides to improve on the
            # performance of our default formatting. see issue #138.
            method
          # second, check if the dev has specified a valid list_ui for this column
          elsif column.list_ui && (method = override_column_ui(column.list_ui))
            [method, true]
          elsif column.column && (method = override_column_ui(column.column_type)) # rubocop:disable Lint/DuplicateBranch
            method
          else
            :format_column_value
          end
        end
      end

      # TODO: move empty_field_text and &nbsp; logic in here?
      # TODO: we need to distinguish between the automatic links *we* create and the ones that the dev specified. some logic may not apply if the dev specified the link.
      def render_list_column(text, column, record)
        if column.link && !skip_action_link?(column.link, record)
          link = column.link
          associated = record.send(column.association.name) if column.association
          authorized = link.action.nil?
          authorized, reason = column_link_authorized?(link, column, record, associated) unless authorized
          render_action_link(link, record, link: text, authorized: authorized, not_authorized_reason: reason)
        elsif inplace_edit?(record, column)
          active_scaffold_inplace_edit(record, column, formatted_column: text)
        elsif column_wrap_tag
          content_tag column_wrap_tag, text
        else
          text
        end
      rescue StandardError => e
        message = "on the ActiveScaffold column = :#{column.name} in #{controller.class}"
        Rails.logger.error "#{e.class.name}: #{e.message} -- #{message}"
        raise e.class, "#{e.message} -- #{message}", e.backtrace
      end

      def column_wrap_tag
        return @_column_wrap_tag if defined? @_column_wrap_tag

        @_column_wrap_tag = (active_scaffold_config.list.wrap_tag if active_scaffold_config.actions.include?(:list))
      end

      # There are two basic ways to clean a column's value: h() and sanitize(). The latter is useful
      # when the column contains *valid* html data, and you want to just disable any scripting. People
      # can always use field overrides to clean data one way or the other, but having this override
      # lets people decide which way it should happen by default.
      #
      # Why is it not a configuration option? Because it seems like a somewhat rare request. But it
      # could eventually be an option in config.list (and config.show, I guess).
      def clean_column_value(value)
        h(value)
      end

      ##
      ## Overrides
      ##
      def active_scaffold_column_text(record, column, ui_options: column.options)
        # `to_s` is necessary to convert objects in serialized columns to string before truncation.
        clean_column_value(truncate(record.send(column.name).to_s, length: ui_options[:truncate] || 50))
      end

      def active_scaffold_column_fulltext(record, column, ui_options: column.options)
        clean_column_value(record.send(column.name))
      end

      def active_scaffold_column_marked(record, column, ui_options: column.options)
        options = {id: nil, object: record}
        content_tag(:span, check_box(:record, column.name, options), class: 'in_place_editor_field', data: {ie_id: record.to_param})
      end

      def active_scaffold_column_checkbox(record, column, ui_options: column.options)
        options = {disabled: true, id: nil, object: record}
        options.delete(:disabled) if inplace_edit?(record, column)
        check_box(:record, column.name, options)
      end

      def active_scaffold_column_boolean(record, column, ui_options: column.options)
        value = record.send(column.name)
        if value.nil? && ui_options[:include_blank]
          value = ui_options[:include_blank]
          value.is_a?(Symbol) ? as_(value) : value
        else
          format_column_value(record, column, value)
        end
      end

      def active_scaffold_column_percentage(record, column, ui_options: column.options)
        options = ui_options[:slider] || {}
        options = options.merge(min: record.send(options[:min_method])) if options[:min_method]
        options = options.merge(max: record.send(options[:max_method])) if options[:max_method]
        value = record.send(options[:value_method]) if options[:value_method]
        as_slider options.merge(value: value || record.send(column.name))
      end

      def active_scaffold_column_month(record, column, ui_options: column.options)
        l record.send(column.name), format: :year_month
      end

      def active_scaffold_column_week(record, column, ui_options: column.options)
        l record.send(column.name), format: :week
      end

      def tel_to(text)
        text = text.to_s
        groups = text.scan(/(?:^\+)?\d+/)
        extension = groups.pop if text.match?(/\s*[^\d\s]+\s*\d+$/)
        link_to text, "tel:#{[groups.join('-'), extension].compact.join(',')}"
      end

      def active_scaffold_column_telephone(record, column, ui_options: column.options)
        phone = record.send column.name
        return if phone.blank?

        phone = number_to_phone(phone) unless ui_options[:format] == false
        tel_to phone
      end

      def column_override(column)
        override_helper column, 'column'
      end
      alias column_override? column_override

      # the naming convention for overriding column types with helpers
      def override_column_ui(list_ui)
        ActiveScaffold::Registry.cache :column_ui_overrides, list_ui do
          method = "active_scaffold_column_#{list_ui}"
          method if respond_to? method
        end
      end
      alias override_column_ui? override_column_ui

      ##
      ## Formatting
      ##

      def read_value_from_record(record, column, join_text = ' - ')
        if grouped_search? && column == search_group_column
          value =
            if search_group_function
              record[column.name]
            elsif search_group_column.group_by
              safe_join column.group_by.map.with_index { |_, index| record["#{column.name}_#{index}"] }, join_text
            end
        end
        value || record.send(column.name)
      end

      FORM_UI_WITH_OPTIONS = %i[select radio].freeze
      def format_column_value(record, column, value = nil)
        value ||= read_value_from_record(record, column) unless record.nil?
        if grouped_search? && column == search_group_column && (search_group_function || search_group_column.group_by)
          format_grouped_search_column(value, column.options)
        elsif column.association.nil?
          form_ui_options = column.form_ui_options || column.options if FORM_UI_WITH_OPTIONS.include?(column.form_ui)
          if form_ui_options&.dig(:options)
            text, val = form_ui_options[:options].find { |t, v| (v.nil? ? t : v).to_s == value.to_s }
            value = active_scaffold_translated_option(column, text, val).first if text
          end
          if value.is_a? Numeric
            format_number_value(value, column.options)
          else
            format_value(value, column.options, column)
          end
        else
          if column.association.collection?
            associated_size = column_association_size(record, column, value) if column.associated_number? # get count before cache association
            if column.association.respond_to_target? && !value.loaded?
              cache_association(record.association(column.name), column, associated_size)
            end
          end
          format_association_value(value, column, associated_size)
        end
      end

      def column_association_size(record, column, value)
        cached_counts = @counts&.dig(column.name)
        if cached_counts
          key = column.association.primary_key if count_on_association_class?(column)
          cached_counts[record.send(key || :id)] || 0
        else
          value.size
        end
      end

      def format_number_value(value, options = {})
        if value
          value =
            case options[:format]
            when :size
              number_to_human_size(value, options[:i18n_options] || {})
            when :percentage
              number_to_percentage(value, options[:i18n_options] || {})
            when :currency
              number_to_currency(value, options[:i18n_options] || {})
            when :i18n_number
              send("number_with_#{value.is_a?(Integer) ? 'delimiter' : 'precision'}", value, options[:i18n_options] || {})
            else
              value
            end
        end
        clean_column_value(value)
      end

      def format_grouped_search_column(value, options = {})
        case search_group_function
        when 'year_month'
          year, month = value.to_s.scan(/(\d*)(\d{2})/)[0]
          I18n.l(Date.new(year.to_i, month.to_i, 1), format: options[:group_format] || search_group_function.to_sym)
        when 'year_quarter'
          year, quarter = value.to_s.scan(/(\d*)(\d)/)[0]
          I18n.t(options[:group_format] || search_group_function, scope: 'date.formats', year: year, quarter: quarter)
        when 'quarter'
          I18n.t(options[:group_format] || search_group_function, scope: 'date.formats', num: value)
        when 'month'
          I18n.l(Date.new(Time.zone.today.year, value, 1), format: options[:group_format] || search_group_function.to_sym)
        when 'year'
          value.to_i
        else
          value
        end
      end

      def association_join_text(column = nil)
        column_value = column&.association_join_text
        return column_value if column_value
        return @_association_join_text if defined? @_association_join_text

        @_association_join_text = active_scaffold_config.list.association_join_text
      end

      def format_collection_association_value(value, column, label_method, size)
        associated_limit = column.associated_limit
        if associated_limit.nil?
          firsts = value.collect(&label_method)
          safe_join firsts, association_join_text(column)
        elsif associated_limit.zero?
          size if column.associated_number?
        else
          firsts = value.loaded? ? value[0, associated_limit] : value.limit(associated_limit)
          firsts = firsts.map(&label_method)
          firsts << '…' if value.size > associated_limit
          text = safe_join firsts, association_join_text(column)
          text << " (#{size})" if column.associated_number? && associated_limit && value.size > associated_limit
          text
        end
      end

      def format_singular_association_value(value, column, label_method)
        if column.association.polymorphic?
          "#{value.class.model_name.human}: #{value.send(label_method)}"
        else
          value.send(label_method)
        end
      end

      def format_association_value(value, column, size)
        method = (column.list_ui_options || column.options)[:label_method] || :to_label
        value =
          if column.association.collection?
            format_collection_association_value(value, column, method, size)
          elsif value
            format_singular_association_value(value, column, method)
          end
        format_value value, nil, column
      end

      def format_value(column_value, options = {}, column = nil)
        options ||= column&.options
        value =
          if column_empty?(column_value)
            empty_field_text(column)
          elsif column_value.is_a?(Time) || column_value.is_a?(Date)
            l(column_value, format: options&.dig(:format) || :default)
          elsif !!column_value == column_value # rubocop:disable Style/DoubleNegation fast check for boolean
            as_(column_value.to_s.to_sym)
          else
            column_value.to_s
          end
        clean_column_value(value)
      end

      def cache_association(association, column, size)
        associated_limit = column.associated_limit
        # we are not using eager loading, cache firsts records in order not to query the database for whole association in a future
        if associated_limit.nil?
          logger.warn "ActiveScaffold: Enable eager loading for #{column.name} association to reduce SQL queries"
        elsif associated_limit.positive?
          # load at least one record more, is needed to display '...'
          association.target = association.reader.limit(associated_limit + 1).select(column.select_associated_columns || "#{association.klass.quoted_table_name}.*").to_a
        elsif @cache_associations
          # set array with at least one element if size > 0, so blank? or present? works, saving [nil] may cause exceptions
          association.target =
            if size.to_i.zero?
              []
            else
              ActiveScaffold::Registry.cache(:cached_empty_association, association.klass) { [association.klass.new] }
            end
        end
      end

      # ==========
      # = Inline Edit =
      # ==========

      def inplace_edit?(record, column)
        return false unless column.inplace_edit
        if controller.respond_to?(:update_authorized?, true)
          return Array(controller.send(:update_authorized?, record, column.name))[0]
        end

        record.authorized_for?(crud_type: :update, column: column.name)
      end

      def inplace_edit_cloning?(column)
        column.inplace_edit != :ajax && (override_form_field?(column) || column.form_ui || (column.column && override_input?(column.column_type)))
      end

      def active_scaffold_inplace_edit_tag_options(record, column)
        @_inplace_edit_title ||= as_(:click_to_edit)
        cell_id = ActiveScaffold::Registry.cache :inplace_edit_id, column.cache_key do
          element_cell_id(id: '--ID--', action: 'update_column', name: column.name.to_s)
        end
        tag_options = {id: cell_id.sub('--ID--', record.id.to_s), class: 'in_place_editor_field',
                       title: @_inplace_edit_title, data: {ie_id: record.to_param}}
        tag_options[:data][:ie_update] = column.inplace_edit if column.inplace_edit != true
        tag_options
      end

      def active_scaffold_inplace_edit(record, column, options = {})
        formatted_column = options[:formatted_column] || format_column_value(record, column)
        @_inplace_edit_handle ||= content_tag(:span, as_(:inplace_edit_handle), class: 'handle')
        span = content_tag(:span, formatted_column, active_scaffold_inplace_edit_tag_options(record, column))
        @_inplace_edit_handle + span
      end

      def inplace_edit_control(column)
        return unless inplace_edit?(active_scaffold_config.model, column) && inplace_edit_cloning?(column)

        column.form_ui = :select if column.association && column.form_ui.nil?
        options = active_scaffold_input_options(column).merge(object: column.active_record_class.new)
        options[:class] = "#{options[:class]} inplace_field"
        options[:'data-id'] = options[:id]
        options[:id] = nil
        content_tag(:div, active_scaffold_input_for(column, nil, options), style: 'display:none;', class: inplace_edit_control_css_class)
      end

      def inplace_edit_control_css_class
        'as_inplace_pattern'
      end

      INPLACE_EDIT_PLURAL_FORM_UI = %i[select record_select].freeze
      def inplace_edit_data(column)
        data = {}
        data[:ie_url] = url_for(params_for(action: 'update_column', column: column.name, id: '__id__'))
        data[:ie_cancel_text] = column.options[:cancel_text] || as_(:cancel)
        data[:ie_loading_text] = column.options[:loading_text] || as_(:loading)
        data[:ie_save_text] = column.options[:save_text] || as_(:update)
        data[:ie_saving_text] = column.options[:saving_text] || as_(:saving)
        data[:ie_rows] = column.options[:rows] || 5 if column.column&.type == :text
        data[:ie_cols] = column.options[:cols] if column.options[:cols]
        data[:ie_size] = column.options[:size] if column.options[:size]
        data[:ie_use_html] = column.options[:use_html] if column.options[:use_html]

        if column.list_ui == :checkbox
          data[:ie_mode] = :inline_checkbox
        elsif inplace_edit_cloning?(column)
          data[:ie_mode] = :clone
        elsif column.inplace_edit == :ajax
          url = url_for(params_for(controller: params_for[:controller], action: 'render_field', id: '__id__', update_column: column.name))
          plural = column.association&.collection? && !override_form_field?(column) && INPLACE_EDIT_PLURAL_FORM_UI.include?(column.form_ui)
          data[:ie_render_url] = url
          data[:ie_mode] = :ajax
          data[:ie_plural] = plural
        end
        data
      end

      # MARK

      def all_marked?
        if active_scaffold_config.mark.mark_all_mode == :page
          @page.items.all? { |record| marked_records.key?(record.id) }
        else
          marked_records.length >= @page.pager.count.to_i
        end
      end

      def mark_column_heading
        tag_options = {
          id: "#{controller_id}_mark_heading",
          class: 'mark_heading in_place_editor_field'
        }
        content_tag(:span, check_box_tag("#{controller_id}_mark_heading_span_input", '1', all_marked?), tag_options)
      end

      # COLUMN HEADINGS

      def column_heading_attributes(column, sorting, sort_direction)
        {id: active_scaffold_column_header_id(column), class: column_heading_class(column, sorting), title: strip_tags(column.description).presence}
      end

      def render_column_heading(column, sorting, sort_direction)
        tag_options = column_heading_attributes(column, sorting, sort_direction)
        if column.name == :as_marked
          tag_options[:data] = {
            ie_mode: :inline_checkbox,
            ie_url: url_for(params_for(action: 'mark', id: '__id__'))
          }
        elsif column.inplace_edit
          tag_options[:data] = inplace_edit_data(column)
        end
        content_tag(:th, column_heading_value(column, sorting, sort_direction) + inplace_edit_control(column), tag_options)
      end

      def column_heading_value(column, sorting, sort_direction)
        if column.name == :as_marked
          mark_column_heading
        elsif column.sortable?
          options = {id: nil, class: 'as_sort',
                     'data-page-history' => controller_id,
                     remote: true, method: :get}
          url_options = {action: :index, page: 1, sort: column.name, sort_direction: sort_direction}
          # :id needed because rails reuse it even if it was deleted from params (like do_refresh_list does)
          url_options[:id] = nil if @remove_id_from_list_links
          url_options = params_for(url_options)
          if !active_scaffold_config.store_user_settings && respond_to?(:search_params) && search_params.present?
            url_options[:search] = search_params
          end
          link_to column_heading_label(column), url_options, options
        else
          content_tag(:p, column_heading_label(column))
        end
      end

      def column_heading_label(column)
        column.label
      end

      # CALCULATIONS

      def column_calculation(column, id_condition: true)
        if column.calculate.instance_of? Proc
          column.calculate.call(@records)
        elsif column.calculate.in? %i[count sum average minimum maximum]
          calculate_query(id_condition: id_condition).calculate(column.calculate, column.grouped_select)
        end
      end

      def render_column_calculation(column, id_condition: true)
        calculation = column_calculation(column, id_condition: id_condition)
        override_formatter = "render_#{column.name}_#{column.calculate.is_a?(Proc) ? :calculate : column.calculate}"
        calculation = send(override_formatter, calculation) if respond_to? override_formatter
        format_column_calculation(column, calculation)
      end

      def format_column_calculation(column, calculation)
        "#{"#{as_(column.calculate)}: " unless column.calculate.is_a? Proc}#{format_column_value nil, column, calculation}"
      end
    end
  end
end
