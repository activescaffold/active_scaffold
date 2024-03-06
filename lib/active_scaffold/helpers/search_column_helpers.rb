module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module SearchColumnHelpers
      # This method decides which input to use for the given column.
      # It does not do any rendering. It only decides which method is responsible for rendering.
      def active_scaffold_search_for(column, options = nil)
        options ||= active_scaffold_search_options(column)
        search_columns = active_scaffold_config.field_search.columns.visible_columns_names
        options = update_columns_options(column, nil, options, form_columns: search_columns, url_params: {form_action: :field_search})
        record = options[:object]
        if column.delegated_association
          record = record.send(column.delegated_association.name) || column.active_record_class.new
          options[:object] = record
        end

        # first, check if the dev has created an override for this specific field for search
        if (method = override_search_field(column))
          send(method, record, options)

        # second, check if the dev has specified a valid search_ui for this column, using specific ui for searches
        elsif column.search_ui && (method = override_search(column.search_ui))
          send(method, column, options, ui_options: column.search_ui_options || column.options)

        # third, check if the dev has specified a valid search_ui for this column, using generic ui for forms
        elsif column.search_ui && (method = override_input(column.search_ui))
          send(method, column, options, ui_options: column.search_ui_options || column.options)

        # fourth, check if the dev has created an override for this specific field
        elsif (method = override_form_field(column))
          send(method, record, options)

        # fallback: we get to make the decision
        elsif column.association || column.virtual?
          active_scaffold_search_text(column, options)

        elsif (method = override_search(column.column.type))
          # if we (or someone else) have created a custom render option for the column type, use that
          send(method, column, options)

        elsif (method = override_input(column.column.type))
          # if we (or someone else) have created a custom render option for the column type, use that
          send(method, column, options)

        else # final ultimate fallback: use rails' generic input method
          # for textual fields we pass different options
          options = active_scaffold_input_text_options(options) if column.text? || column.number?
          text_field(:record, column.name, options.merge(column.options))
        end
      rescue StandardError => e
        logger.error "#{e.class.name}: #{e.message} -- on the ActiveScaffold column = :#{column.name} in #{controller.class}"
        raise e
      end

      # the standard active scaffold options used for class, name and scope
      def active_scaffold_search_options(column)
        {:name => "search[#{column.name}]", :class => "#{column.name}-input", :id => "search_#{column.name}", :value => field_search_params[column.name.to_s]}
      end

      def search_attribute(column, record)
        column_options = active_scaffold_search_options(column).merge(:object => record)
        content_tag :dl do
          content_tag(:dt, label_tag(search_label_for(column, column_options), search_column_label(column, record))) <<
            content_tag(:dd, active_scaffold_search_for(column, column_options))
        end
      end

      def search_label_for(column, options)
        options[:id] unless %i[range integer decimal float string date_picker datetime_picker calendar_date_select].include? column.search_ui
      end

      ##
      ## Search input methods
      ##

      def active_scaffold_search_multi_select(column, options, ui_options: column.options)
        record = options.delete(:object)
        associated = options.delete :value
        associated = [associated].compact unless associated.is_a? Array

        if column.association
          associated.collect!(&:to_i)
          method = ui_options[:label_method] || :to_label
          select_options = sorted_association_options_find(column.association, nil, record).collect do |r|
            [r.send(method), r.id]
          end
        else
          select_options = active_scaffold_enum_options(column, record, ui_options: ui_options).collect do |text, value|
            active_scaffold_translated_option(column, text, value)
          end
        end
        return as_(:no_options) if select_options.empty?

        active_scaffold_checkbox_list(column, select_options, associated, options, ui_options: ui_options)
      end

      def active_scaffold_search_select(column, html_options, options = {}, ui_options: column.options)
        record = html_options.delete(:object)
        associated = html_options.delete :value
        if column.association
          associated = associated.is_a?(Array) ? associated.map(&:to_i) : associated.to_i unless associated.nil?
          method = column.association.belongs_to? ? column.association.foreign_key : column.name
          select_options = sorted_association_options_find(column.association, false, record)
        else
          method = column.name
          select_options = active_scaffold_enum_options(column, record, ui_options: ui_options).collect do |text, value|
            active_scaffold_translated_option(column, text, value)
          end
        end

        options = options.merge(selected: associated).merge ui_options
        html_options.merge! ui_options[:html_options] || {}
        if html_options[:multiple]
          active_scaffold_select_name_with_multiple html_options
        else
          options[:include_blank] ||= as_(:_select_)
          active_scaffold_translate_select_options(options)
        end

        if (optgroup = options.delete(:optgroup))
          select(:record, method, active_scaffold_grouped_options(column, select_options, optgroup), options, html_options)
        elsif column.association
          collection_select(:record, method, select_options, :id, ui_options[:label_method] || :to_label, options, html_options)
        else
          select(:record, method, select_options, options, html_options)
        end
      end

      def active_scaffold_search_select_multiple(column, options, ui_options: column.options)
        active_scaffold_search_select(column, options.merge(multiple: true), ui_options: ui_options)
      end

      def active_scaffold_search_draggable(column, options, ui_options: column.options)
        active_scaffold_search_multi_select(column, options.merge(draggable_lists: true), ui_options: ui_options)
      end

      def active_scaffold_search_text(column, options, ui_options: column.options)
        text_field :record, column.name, active_scaffold_input_text_options(options)
      end

      # we can't use active_scaffold_input_boolean because we need to have a nil value even when column can't be null
      # to decide whether search for this field or not
      def active_scaffold_search_boolean(column, options, ui_options: column.options)
        select_options = []
        select_options << [as_(:_select_), nil]
        if column.column&.null
          null_label = ui_options[:include_blank] || :null
          null_label = as_(null_label) if null_label.is_a?(Symbol)
          select_options << [null_label, 'null']
        end
        select_options << [as_(:true), true] # rubocop:disable Lint/BooleanSymbol
        select_options << [as_(:false), false] # rubocop:disable Lint/BooleanSymbol

        select_tag(options[:name], options_for_select(select_options, ActiveScaffold::Core.column_type_cast(options[:value], column.column)), :id => options[:id])
      end
      # we can't use checkbox ui because it's not possible to decide whether search for this field or not
      alias active_scaffold_search_checkbox active_scaffold_search_boolean

      def active_scaffold_group_search_column(record, options)
        select_tag 'search[active_scaffold_group]', options_for_select(active_scaffold_group_search_options, selected: field_search_params['active_scaffold_group'])
      end

      def active_scaffold_group_search_options
        options = active_scaffold_config.field_search.group_options.collect do |text, value|
          active_scaffold_translated_option(active_scaffold_group_column, text, value)
        end
        [[as_(:no_group), '']].concat options
      end

      def active_scaffold_group_column
        return if active_scaffold_config.field_search.group_options.blank?
        @_active_scaffold_group_column ||= begin
          column = ActiveScaffold::DataStructures::Column.new(:active_scaffold_group, active_scaffold_config.model)
          column.label = :group_by
          column
        end
      end

      def active_scaffold_search_null(column, options, ui_options: column.options)
        select_options = []
        select_options << [as_(:_select_), nil]
        select_options.concat(ActiveScaffold::Finder::NULL_COMPARATORS.collect { |comp| [as_(comp), comp] })
        select_tag(options[:name], options_for_select(select_options, options[:value]), :id => options[:id])
      end

      def field_search_params_range_values(column)
        values = field_search_params[column.name.to_s]
        return nil unless values.is_a? Hash
        [values['opt'], values['from'].presence, values['to'].presence]
      end

      def active_scaffold_search_range_string?(column)
        column.text? || column.search_ui == :string
      end

      def active_scaffold_search_range_comparator_options(column, ui_options: column.options)
        select_options = ActiveScaffold::Finder::NUMERIC_COMPARATORS.collect { |comp| [as_(comp.downcase.to_sym), comp] }
        if active_scaffold_search_range_string?(column)
          comparators = ActiveScaffold::Finder::STRING_COMPARATORS.collect { |title, comp| [as_(title), comp] }
          select_options.unshift(*comparators)
        end
        if include_null_comparators? column, ui_options: ui_options
          select_options.concat(ActiveScaffold::Finder::NULL_COMPARATORS.collect { |comp| [as_(comp), comp] })
        end
        select_options
      end

      def include_null_comparators?(column, ui_options: column.options)
        return ui_options[:null_comparators] if ui_options.key? :null_comparators
        if column.association
          !column.association.belongs_to? || active_scaffold_config.columns[column.association.foreign_key].column&.null
        else
          column.column&.null
        end
      end

      def active_scaffold_search_range(column, options, input_method = :text_field_tag, input_options = {}, ui_options: column.options)
        opt_value, from_value, to_value = field_search_params_range_values(column)

        select_options = active_scaffold_search_range_comparator_options(column, ui_options: ui_options)
        text_field_size = active_scaffold_search_range_string?(column) ? 15 : 10
        opt_value ||= select_options[0][1]

        from_value = controller.class.condition_value_for_numeric(column, from_value)
        to_value = controller.class.condition_value_for_numeric(column, to_value)
        from_value = format_number_value(from_value, ui_options) if from_value.is_a?(Numeric)
        to_value = format_number_value(to_value, ui_options) if to_value.is_a?(Numeric)
        html = select_tag("#{options[:name]}[opt]", options_for_select(select_options, opt_value),
                          :id => "#{options[:id]}_opt", :class => 'as_search_range_option')
        from_options = active_scaffold_input_text_options(input_options.merge(:id => options[:id], :size => text_field_size))
        to_options = from_options.merge(:id => "#{options[:id]}_to")
        html << content_tag('span', :id => "#{options[:id]}_numeric", :style => ActiveScaffold::Finder::NULL_COMPARATORS.include?(opt_value) ? 'display: none' : nil) do
          send(input_method, "#{options[:name]}[from]", from_value, input_options) <<
            content_tag(
              :span,
              safe_join([' - ', send(input_method, "#{options[:name]}[to]", to_value, to_options)]),
              :id => "#{options[:id]}_between", :class => 'as_search_range_between', :style => ('display: none' unless opt_value == 'BETWEEN')
            )
        end
        content_tag :span, html, :class => 'search_range'
      end
      alias active_scaffold_search_string active_scaffold_search_range

      def active_scaffold_search_integer(column, options, ui_options: column.options)
        active_scaffold_search_range(column, options, :number_field_tag, {step: '1'}, ui_options: ui_options) # rubocop:disable Style/BracesAroundHashParameters
      end

      def active_scaffold_search_decimal(column, options, ui_options: column.options)
        active_scaffold_search_range(column, options, :number_field_tag, {step: :any}, ui_options: ui_options) # rubocop:disable Style/BracesAroundHashParameters
      end
      alias active_scaffold_search_float active_scaffold_search_decimal

      def field_search_datetime_value(value)
        Time.zone.local(value[:year].to_i, value[:month].to_i, value[:day].to_i, value[:hour].to_i, value[:minute].to_i, value[:second].to_i) unless value.nil? || value[:year].blank?
      end

      def active_scaffold_search_datetime(column, options, ui_options: column.options)
        _, from_value, to_value = field_search_params_range_values(column)
        options = ui_options.merge(options)
        type = "#{'date' unless options[:discard_date]}#{'time' unless options[:discard_time]}"
        use_select = options.delete(:use_select)
        from_name = "#{options[:name]}[from]"
        to_name = "#{options[:name]}[to]"
        if use_select
          helper = "select_#{type}"
          fields = [
            send(helper, field_search_datetime_value(from_value), options.reverse_merge(include_blank: true, prefix: from_name)),
            send(helper, field_search_datetime_value(to_value), options.reverse_merge(include_blank: true, prefix: to_name))
          ]
        else
          helper = "#{type}#{'_local' if type == 'datetime'}_field_tag"
          fields = [
            send(helper, from_name, field_search_datetime_value(from_value), options.except(:name, :object).merge(id: "#{options[:id]}_from")),
            send(helper, to_name, field_search_datetime_value(to_value), options.except(:name, :object).merge(id: "#{options[:id]}_to"))
          ]
        end

        safe_join fields, ' - '
      end

      def active_scaffold_search_date(column, options, ui_options: column.options)
        active_scaffold_search_datetime(column, options.merge!(:discard_time => true), ui_options: ui_options)
      end

      def active_scaffold_search_time(column, options, ui_options: column.options)
        active_scaffold_search_datetime(column, options.merge!(:discard_date => true), ui_options: ui_options)
      end
      alias active_scaffold_search_timestamp active_scaffold_search_datetime

      ##
      ## Search column override signatures
      ##

      def search_column_label(column, record)
        column.label
      end

      def override_search_field(column)
        override_helper column, 'search_column'
      end

      # the naming convention for overriding search input types with helpers
      def override_search(form_ui)
        method = "active_scaffold_search_#{form_ui}"
        method if respond_to? method
      end

      def visibles_and_hiddens(search_config)
        visibles = []
        hiddens = []
        search_config.columns.each_column do |column|
          next unless column.search_sql
          if search_config.optional_columns.include?(column.name) && !searched_by?(column)
            hiddens << column
          else
            visibles << column
          end
        end
        if active_scaffold_group_column
          columns = grouped_search? || search_config.optional_columns.empty? ? visibles : hiddens
          columns << active_scaffold_group_column
        end
        [visibles, hiddens]
      end

      def searched_by?(column)
        value = field_search_params[column.name.to_s]
        case value
        when Hash
          value['from'].present?
        when String
          value.present?
        else
          false
        end
      end
    end
  end
end
