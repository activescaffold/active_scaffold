# coding: utf-8
module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a List Column
    module ListColumnHelpers
      def get_column_value(record, column)
        method = get_column_method(record, column)
        value = send(method, record, column)
        value = '&nbsp;'.html_safe if value.nil? || value.blank? # fix for IE 6
        return value
      rescue StandardError => e
        logger.error "#{e.class.name}: #{e.message} -- on the ActiveScaffold column = :#{column.name} in #{controller.class}, record: #{record.inspect}"
        raise e
      end

      def get_column_method(record, column)
        # check for an override helper
        column.list_method ||= begin
          if (method = column_override(column))
            # we only pass the record as the argument. we previously also passed the formatted_value,
            # but mike perham pointed out that prohibited the usage of overrides to improve on the
            # performance of our default formatting. see issue #138.
            method
          # second, check if the dev has specified a valid list_ui for this column
          elsif column.list_ui && (method = override_column_ui(column.list_ui))
            method
          elsif column.column && (method = override_column_ui(column.column.type))
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
          render_action_link(link, record, :link => text, :authorized => link.action.nil? || column_link_authorized?(link, column, record, associated))
        elsif inplace_edit?(record, column)
          active_scaffold_inplace_edit(record, column, :formatted_column => text)
        elsif active_scaffold_config.actions.include?(:list) && active_scaffold_config.list.wrap_tag
          content_tag active_scaffold_config.list.wrap_tag, text
        else
          text
        end
      rescue StandardError => e
        logger.error "#{e.class.name}: #{e.message} -- on the ActiveScaffold column = :#{column.name} in #{controller.class}"
        raise e
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

      ##
      ## Overrides
      ##
      def active_scaffold_column_text(record, column)
        # `to_s` is necessary to convert objects in serialized columns to string before truncation.
        clean_column_value(truncate(record.send(column.name).to_s, :length => column.options[:truncate] || 50))
      end

      def active_scaffold_column_fulltext(record, column)
        clean_column_value(record.send(column.name))
      end

      def active_scaffold_column_marked(record, column)
        options = {:id => nil, :object => record}
        content_tag(:span, check_box(:record, column.name, options), :class => 'in_place_editor_field', :data => {:ie_id => record.to_param})
      end

      def active_scaffold_column_checkbox(record, column)
        options = {:disabled => true, :id => nil, :object => record}
        options.delete(:disabled) if inplace_edit?(record, column)
        check_box(:record, column.name, options)
      end
      
      def active_scaffold_column_percentage(record, column)
        options = column.options[:slider] || {}
        options = options.merge(min: record.send(options[:min_method])) if options[:min_method]
        options = options.merge(max: record.send(options[:max_method])) if options[:max_method]
        value = record.send(options[:value_method]) if options[:value_method]
        as_slider options.merge(value: value || record.send(column.name))
      end

      def column_override(column)
        override_helper column, 'column'
      end
      alias_method :column_override?, :column_override

      # the naming convention for overriding column types with helpers
      def override_column_ui(list_ui)
        @_column_ui_overrides ||= {}
        return @_column_ui_overrides[list_ui] if @_column_ui_overrides.include? list_ui
        method = "active_scaffold_column_#{list_ui}"
        @_column_ui_overrides[list_ui] = (method if respond_to? method)
      end
      alias_method :override_column_ui?, :override_column_ui

      ##
      ## Formatting
      ##
      def format_column_value(record, column, value = nil)
        value ||= record.send(column.name) unless record.nil?
        if column.association.nil?
          if [:select, :radio].include?(column.form_ui) && column.options[:options]
            text, val = column.options[:options].find { |text, val| (val.nil? ? text : val).to_s == value.to_s }
            value = active_scaffold_translated_option(column, text, val).first if text
          end
          if value.is_a? Numeric
            format_number_value(value, column.options)
          else
            format_value(value, column.options)
          end
        else
          if column.plural_association?
            associated_size = value.size if column.associated_number? # get count before cache association
            cache_association(record.association(column.name), column, associated_size) unless value.loaded?
          end
          format_association_value(value, column, associated_size)
        end
      end

      def format_number_value(value, options = {})
        if value
          value = case options[:format]
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

      def format_collection_association_value(value, column, label_method, size)
        if column.associated_limit.nil?
          firsts = value.collect(&label_method)
        elsif column.associated_limit == 0
          size if column.associated_number?
        else
          firsts = value.first(column.associated_limit)
          firsts.collect!(&label_method)
          firsts << '…' if value.size > column.associated_limit
          text = firsts.join(h(active_scaffold_config.list.association_join_text)).html_safe
          text << " (#{size})" if column.associated_number? && column.associated_limit && value.size > column.associated_limit
          text
        end
      end

      def format_singular_association_value(value, column, label_method)
        if column.polymorphic_association?
          "#{value.class.model_name.human}: #{value.send(label_method)}"
        else
          value.send(label_method)
        end
      end

      def format_association_value(value, column, size)
        method = column.options[:label_method] || :to_label
        value =
          if column.association.collection?
            format_collection_association_value(value, column, method, size)
          elsif value
            format_singular_association_value(value, column, method)
          end
        format_value value
      end

      def format_value(column_value, options = {})
        value =
          if column_empty?(column_value)
            empty_field_text
          elsif column_value.is_a?(Time) || column_value.is_a?(Date)
            l(column_value, :format => options[:format] || :default)
          elsif [FalseClass, TrueClass].include?(column_value.class)
            as_(column_value.to_s.to_sym)
          else
            column_value.to_s
          end
        clean_column_value(value)
      end

      def cache_association(association, column, size)
        # we are not using eager loading, cache firsts records in order not to query the database for whole association in a future
        if column.associated_limit.nil?
          logger.warn "ActiveScaffold: Enable eager loading for #{column.name} association to reduce SQL queries"
        elsif column.associated_limit > 0
          # load at least one record more, is needed to display '...'
          association.target = association.reader.limit(column.associated_limit + 1).select(column.select_associated_columns || "#{association.klass.quoted_table_name}.*").to_a
        elsif @cache_associations
          association.target = []
        end
      end

      # ==========
      # = Inline Edit =
      # ==========

      def inplace_edit?(record, column)
        return unless column.inplace_edit
        editable = controller.send(:update_authorized?, record) if controller.respond_to?(:update_authorized?, true)
        editable || record.authorized_for?(:crud_type => :update, :column => column.name)
      end

      def inplace_edit_cloning?(column)
        column.inplace_edit != :ajax && (override_form_field?(column) || column.form_ui || (column.column && override_input?(column.column.type)))
      end

      def active_scaffold_inplace_edit_tag_options(record, column)
        id_options = {:id => record.id.to_s, :action => 'update_column', :name => column.name.to_s}
        tag_options = {:id => element_cell_id(id_options), :class => 'in_place_editor_field',
                       :title => as_(:click_to_edit), :data => {:ie_id => record.to_param}}
        tag_options[:data][:ie_update] = column.inplace_edit if column.inplace_edit != true
        tag_options
      end

      def active_scaffold_inplace_edit(record, column, options = {})
        formatted_column = options[:formatted_column] || format_column_value(record, column)
        content_tag(:span, as_(:inplace_edit_handle), :class => 'handle') <<
          content_tag(:span, formatted_column, active_scaffold_inplace_edit_tag_options(record, column))
      end

      def inplace_edit_control(column)
        return unless inplace_edit?(active_scaffold_config.model, column) && inplace_edit_cloning?(column)
        old_record, @record = @record, active_scaffold_config.model.new # TODO: remove when relying on @record is removed
        column = column.clone
        column.options = column.options.clone
        column.form_ui = :select if column.association && column.form_ui.nil?
        options = active_scaffold_input_options(column).merge(:object => active_scaffold_config.model.new)
        options[:class] = "#{options[:class]} inplace_field"
        options[:"data-id"] = options[:id]
        options[:id] = nil
        content_tag(:div, active_scaffold_input_for(column, nil, options), :style => 'display:none;', :class => inplace_edit_control_css_class).tap do
          @record = old_record # TODO: remove when relying on @record is removed
        end
      end

      def inplace_edit_control_css_class
        'as_inplace_pattern'
      end

      def inplace_edit_data(column)
        data = {}
        data[:ie_url] = url_for(params_for(:action => 'update_column', :column => column.name, :id => '__id__'))
        data[:ie_cancel_text] = column.options[:cancel_text] || as_(:cancel)
        data[:ie_loading_text] = column.options[:loading_text] || as_(:loading)
        data[:ie_save_text] = column.options[:save_text] || as_(:update)
        data[:ie_saving_text] = column.options[:saving_text] || as_(:saving)
        data[:ie_rows] = column.options[:rows] || 5 if column.column.try(:type) == :text
        data[:ie_cols] = column.options[:cols] if column.options[:cols]
        data[:ie_size] = column.options[:size] if column.options[:size]
        data[:ie_use_html] = column.options[:use_html] if column.options[:use_html]

        if column.list_ui == :checkbox
          data[:ie_mode] = :inline_checkbox
        elsif inplace_edit_cloning?(column)
          data[:ie_mode] = :clone
        elsif column.inplace_edit == :ajax
          url = url_for(:controller => params_for[:controller], :action => 'render_field', :id => '__id__', :update_column => column.name)
          plural = column.plural_association? && !override_form_field?(column) && [:select, :record_select].include?(column.form_ui)
          data[:ie_render_url] = url
          data[:ie_mode] = :ajax
          data[:ie_plural] = plural
        end
        data
      end

      def all_marked?
        if active_scaffold_config.mark.mark_all_mode == :page
          @page.items.detect { |record| !marked_records.include?(record.id) }.nil?
        else
          marked_records.length >= @page.pager.count.to_i
        end
      end

      def mark_column_heading
        tag_options = {
          :id => "#{controller_id}_mark_heading",
          :class => 'mark_heading in_place_editor_field'
        }
        content_tag(:span, check_box_tag("#{controller_id}_mark_heading_span_input", '1', all_marked?), tag_options)
      end

      def column_heading_attributes(column, sorting, sort_direction)
        {:id => active_scaffold_column_header_id(column), :class => column_heading_class(column, sorting), :title => strip_tags(column.description).presence}
      end

      def render_column_heading(column, sorting, sort_direction)
        tag_options = column_heading_attributes(column, sorting, sort_direction)
        if column.name == :as_marked
          tag_options[:data] = {
            :ie_mode => :inline_checkbox,
            :ie_url => url_for(params_for(:action => 'mark', :id => '__id__'))
          }
        else
          tag_options[:data] = inplace_edit_data(column) if column.inplace_edit
        end
        content_tag(:th, column_heading_value(column, sorting, sort_direction) + inplace_edit_control(column), tag_options)
      end

      def column_heading_value(column, sorting, sort_direction)
        if column.name == :as_marked
          mark_column_heading
        elsif column.sortable?
          options = {:id => nil, :class => 'as_sort',
                     'data-page-history' => controller_id,
                     :remote => true, :method => :get}
          # :id needed because rails reuse it even if we delete from params (like do_refresh_list does)
          url_options = params_for(:action => :index, :page => 1, :id => params[:id],
                                   :sort => column.name, :sort_direction => sort_direction)
          unless active_scaffold_config.store_user_settings
            url_options.merge!(:search => search_params) if search_params.present?
          end
          link_to column_heading_label(column), url_options, options
        else
          content_tag(:p, column_heading_label(column))
        end
      end

      def column_heading_label(column)
        column.label
      end
    end
  end
end
