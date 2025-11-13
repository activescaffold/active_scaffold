module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module SearchColumnHelpers
      # This method decides which input to use for the given column.
      # It does not do any rendering. It only decides which method is responsible for rendering.
      def active_scaffold_search_for(column, options = nil)
        options ||= active_scaffold_search_options(column)
        if active_scaffold_config.field_search.update_columns
          search_columns = active_scaffold_config.field_search.columns.visible_columns_names
          options = update_columns_options(column, nil, options, form_columns: search_columns, url_params: {form_action: :field_search})
        end
        record = options[:object]
        if column.delegated_association
          record = record.send(column.delegated_association.name) || column.active_record_class.new
          options[:object] = record
        end

        # first, check if the dev has created an override for this specific field for search
        if (method = override_search_field(column))
          send(method, record, options)

        # second, check if the dev has specified a valid search_ui for this column, using specific ui for searches
        # or generic ui for forms
        elsif column.search_ui && (method = override_search(column.search_ui) || override_input(column.search_ui))
          send(method, column, options, ui_options: column.search_ui_options || column.options)

        # third, check if the dev has created an override for this specific field
        elsif (method = override_form_field(column)) # rubocop:disable Lint/DuplicateBranch
          send(method, record, options)

        # fallback: we get to make the decision
        elsif column.association || column.virtual?
          active_scaffold_search_text(column, options)

        elsif (method = override_search(column.column_type) || override_input(column.column_type))
          # if we (or someone else) have created a custom render option for the column type, use that
          send(method, column, options)

        else # final ultimate fallback: use rails' generic input method
          # for textual fields we pass different options
          options = active_scaffold_input_text_options(options) if column.text? || column.number?
          text_field(:record, column.name, options.merge(column.options))
        end
      rescue StandardError => e
        Rails.logger.error "#{e.class.name}: #{e.message} -- on the ActiveScaffold column = :#{column.name} in #{controller.class}"
        raise e
      end

      # the standard active scaffold options used for class, name and scope
      def active_scaffold_search_options(column)
        {name: "search[#{column.name}]", class: "#{column.name}-input", id: "search_#{column.name}", value: field_search_params[column.name.to_s]}
      end

      def search_attribute(column, record)
        column_options = active_scaffold_search_options(column).merge(object: record)
        search_attribute_html(
          column,
          label_tag(search_label_for(column, column_options), search_column_label(column, record)),
          active_scaffold_search_for(column, column_options)
        )
      end

      def search_attribute_html(column, label, field)
        content_tag :dl, content_tag(:dt, label) << content_tag(:dd, field)
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
          helper_method = association_helper_method(column.association, :sorted_association_options_find)
          select_options = send(helper_method, column.association, nil, record).collect do |r|
            [r.send(method), r.id]
          end
        else
          enum_options_method = override_helper_per_model(:active_scaffold_enum_options, record.class)
          select_options = send(enum_options_method, column, record, ui_options: ui_options).collect do |text, value|
            active_scaffold_translated_option(column, text, value)
          end
        end
        return as_(:no_options) if select_options.empty?

        active_scaffold_checkbox_list(column, select_options, associated, options, ui_options: ui_options)
      end

      def active_scaffold_search_select(column, html_options, options = {}, ui_options: column.options)
        record = html_options.delete(:object)
        associated = html_options.delete :value
        if include_null_comparators?(column, ui_options: ui_options)
          range_opts = html_options.slice(:name, :id)
          range_opts[:opt_value], associated, = field_search_params_range_values(column)
          operators = active_scaffold_search_select_comparator_options(column, ui_options: ui_options)
          html_options[:name] += '[from]'
        end

        if column.association
          associated = associated.is_a?(Array) ? associated.map(&:to_i) : associated.to_i unless associated.nil?
          method = column.association.belongs_to? ? column.association.foreign_key : column.name
          helper_method = association_helper_method(column.association, :sorted_association_options_find)
          select_options = send(helper_method, column.association, false, record)
        else
          method = column.name
          enum_options_method = override_helper_per_model(:active_scaffold_enum_options, record.class)
          select_options = send(enum_options_method, column, record, ui_options: ui_options).collect do |text, value|
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

        select =
          if (optgroup = options.delete(:optgroup))
            select(:record, method, active_scaffold_grouped_options(column, select_options, optgroup), options, html_options)
          elsif column.association
            collection_select(:record, method, select_options, :id, ui_options[:label_method] || :to_label, options, html_options)
          else
            select(:record, method, select_options, options, html_options)
          end

        operators ? build_active_scaffold_search_range_ui(operators, select, **range_opts) : select
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
        if column.null?
          null_label = ui_options[:include_blank] || :null
          null_label = as_(null_label) if null_label.is_a?(Symbol)
          select_options << [null_label, 'null']
        end
        select_options << [as_(:true), true] # rubocop:disable Lint/BooleanSymbol
        select_options << [as_(:false), false] # rubocop:disable Lint/BooleanSymbol

        select_tag(options[:name], options_for_select(select_options, ActiveScaffold::Core.column_type_cast(options[:value], column.column)), id: options[:id])
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
        select_tag(options[:name], options_for_select(select_options, options[:value]), id: options[:id])
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
        select_options = []
        if active_scaffold_search_range_string?(column)
          if column.search_sql.present?
            select_options.concat(ActiveScaffold::Finder::STRING_COMPARATORS.collect { |title, comp| [as_(title), comp] })
          end
          if ActiveScaffold::Finder::LOGICAL_COMPARATORS.present? && column.logical_search.present?
            select_options.concat(ActiveScaffold::Finder::LOGICAL_COMPARATORS.collect { |comp| [as_(comp.downcase.to_sym), comp] })
          end
        end
        if column.search_sql.present?
          select_options.concat(ActiveScaffold::Finder::NUMERIC_COMPARATORS.collect { |comp| [as_(comp.downcase.to_sym), comp] })
          if include_null_comparators? column, ui_options: ui_options
            select_options.concat(ActiveScaffold::Finder::NULL_COMPARATORS.collect { |comp| [as_(comp), comp] })
          end
        end
        select_options
      end

      def active_scaffold_search_select_comparator_options(column, ui_options: column.options)
        select_options = [[as_(:'='), '=']]
        select_options.concat(ActiveScaffold::Finder::NULL_COMPARATORS.collect { |comp| [as_(comp), comp] })
        select_options
      end

      def include_null_comparators?(column, ui_options: column.options)
        return ui_options[:null_comparators] if ui_options.key? :null_comparators

        if column.association
          !column.association.belongs_to? || active_scaffold_config.columns[column.association.foreign_key].null?
        else
          column.null?
        end
      end

      def active_scaffold_search_range(column, options, input_method = :text_field_tag, input_options = {}, ui_options: column.options)
        opt_value, from_value, to_value = field_search_params_range_values(column)

        operators = active_scaffold_search_range_comparator_options(column, ui_options: ui_options)
        text_field_size = active_scaffold_search_range_string?(column) ? 15 : 10

        from_value = controller.class.condition_value_for_numeric(column, from_value)
        to_value = controller.class.condition_value_for_numeric(column, to_value)
        from_value = format_number_value(from_value, ui_options) if from_value.is_a?(Numeric)
        to_value = format_number_value(to_value, ui_options) if to_value.is_a?(Numeric)
        from_options = active_scaffold_input_text_options(input_options.merge(id: options[:id], size: text_field_size))
        to_options = from_options.merge(id: "#{options[:id]}_to")

        from_field = send(input_method, "#{options[:name]}[from]", from_value, input_options)
        to_field = send(input_method, "#{options[:name]}[to]", to_value, to_options)
        build_active_scaffold_search_range_ui(operators, from_field, to_field, opt_value: opt_value, **options.slice(:name, :id))
      end
      alias active_scaffold_search_string active_scaffold_search_range

      def build_active_scaffold_search_range_ui(operators, from, to = nil, name:, id:, opt_value: nil)
        opt_value ||= operators[0][1]
        html = select_tag("#{name}[opt]", options_for_select(operators, opt_value),
                          id: "#{id}_opt", class: 'as_search_range_option')
        if to
          from << content_tag(
            :span,
            safe_join([' - ', to]),
            id: "#{id}_between", class: 'as_search_range_between', style: ('display: none' unless opt_value == 'BETWEEN')
          )
        end
        html << content_tag('span', from, id: "#{id}_numeric", style: ActiveScaffold::Finder::NULL_COMPARATORS.include?(opt_value) ? 'display: none' : nil)
        content_tag :span, html, class: 'search_range'
      end

      def active_scaffold_search_integer(column, options, ui_options: column.options)
        number_opts = ui_options.slice(:step, :min, :max).reverse_merge(step: '1')
        active_scaffold_search_range(column, options, :number_field_tag, number_opts, ui_options: ui_options)
      end

      def active_scaffold_search_decimal(column, options, ui_options: column.options)
        number_opts = ui_options.slice(:step, :min, :max).reverse_merge(step: :any)
        active_scaffold_search_range(column, options, :number_field_tag, number_opts, ui_options: ui_options)
      end
      alias active_scaffold_search_float active_scaffold_search_decimal

      def active_scaffold_search_datetime(column, options, ui_options: column.options, field_ui: column.search_ui || :datetime)
        current_search = {'from' => nil, 'to' => nil, 'opt' => 'BETWEEN',
                          'number' => 1, 'unit' => 'DAYS', 'range' => nil}
        current_search.merge!(options[:value]) unless options[:value].nil?
        tags = [
          active_scaffold_search_datetime_comparator_tag(column, options, current_search, ui_options: column.options),
          active_scaffold_search_datetime_trend_tag(column, options, current_search),
          active_scaffold_search_datetime_numeric_tag(column, options, current_search, ui_options: ui_options, field_ui: field_ui),
          active_scaffold_search_datetime_range_tag(column, options, current_search)
        ]
        safe_join tags, '&nbsp;'.html_safe
      end

      def active_scaffold_search_timestamp(column, options, ui_options: column.options)
        active_scaffold_search_datetime(column, options, ui_options: ui_options, field_ui: :datetime)
      end

      def active_scaffold_search_time(column, options, ui_options: column.options)
        active_scaffold_search_datetime(column, options, ui_options: ui_options, field_ui: :time)
      end

      def active_scaffold_search_date(column, options, ui_options: column.options)
        active_scaffold_search_datetime(column, options, ui_options: ui_options, field_ui: :date)
      end

      def active_scaffold_search_datetime_comparator_options(column, ui_options: column.options)
        select_options = ActiveScaffold::Finder::DATE_COMPARATORS.collect { |comp| [as_(comp.downcase.to_sym), comp] }
        select_options.concat(ActiveScaffold::Finder::NUMERIC_COMPARATORS.collect { |comp| [as_(comp.downcase.to_sym), comp] })
        if include_null_comparators? column, ui_options: ui_options
          select_options.concat(ActiveScaffold::Finder::NULL_COMPARATORS.collect { |comp| [as_(comp), comp] })
        end
        select_options
      end

      def active_scaffold_search_datetime_comparator_tag(column, options, current_search, ui_options: column.options)
        choices = options_for_select(active_scaffold_search_datetime_comparator_options(column, ui_options: ui_options), current_search['opt'])
        select_tag("#{options[:name]}[opt]", choices, id: "#{options[:id]}_opt", class: 'as_search_range_option as_search_date_time_option')
      end

      def active_scaffold_search_datetime_numeric_tag(column, options, current_search, ui_options: column.options, field_ui: column.search_ui)
        helper = "active_scaffold_search_#{field_ui}_field"
        numeric_controls = [
          send(helper, column, options, current_search, 'from', ui_options: ui_options),
          content_tag(:span, id: "#{options[:id]}_between", class: 'as_search_range_between',
                             style: ('display: none' unless current_search['opt'] == 'BETWEEN')) do
            safe_join([' - ', send(helper, column, options, current_search, 'to', ui_options: ui_options)])
          end
        ]
        show = current_search.key?(:show) ? current_search[:show] : ActiveScaffold::Finder::NUMERIC_COMPARATORS.include?(current_search['opt'])
        content_tag('span', safe_join(numeric_controls),
                    id: "#{options[:id]}_numeric", class: 'search-date-numeric',
                    style: ('display: none' unless show))
      end

      def active_scaffold_search_datetime_trend_tag(column, options, current_search)
        trend_controls = [
          text_field_tag("#{options[:name]}[number]", current_search['number'], class: 'text-input', size: 10, autocomplete: 'off'),
          select_tag("#{options[:name]}[unit]",
                     options_for_select(active_scaffold_search_datetime_trend_units(column), current_search['unit']),
                     class: 'text-input')
        ]
        show = current_search.key?(:show) ? current_search[:show] : current_search['opt'] == 'PAST' || current_search['opt'] == 'FUTURE'
        content_tag('span', safe_join(trend_controls, ' '),
                    id: "#{options[:id]}_trend", class: 'search-date-trend',
                    style: ('display: none' unless show))
      end

      def active_scaffold_search_datetime_trend_units(column)
        options = ActiveScaffold::Finder::DATE_UNITS.collect { |unit| [as_(unit.downcase.to_sym), unit] }
        options = ActiveScaffold::Finder::TIME_UNITS.collect { |unit| [as_(unit.downcase.to_sym), unit] } + options if column_datetime?(column)
        options
      end

      def active_scaffold_search_datetime_range_tag(column, options, current_search)
        values = ActiveScaffold::Finder::DATE_RANGES.collect { |range| [as_(range.downcase.to_sym), range] }
        range_controls = select_tag("#{options[:name]}[range]",
                                    options_for_select(values, current_search['range']),
                                    class: 'text-input', id: nil)
        show = current_search.key?(:show) ? current_search[:show] : current_search['opt'] == 'RANGE'
        content_tag('span', range_controls,
                    id: "#{options[:id]}_range", class: 'search-date-range',
                    style: ('display: none' unless show))
      end

      def column_datetime?(column)
        !column.column.nil? && %i[datetime time].include?(column.column_type)
      end

      def active_scaffold_search_datetime_field(column, options, current_search, name, ui_options: column.options)
        options = ui_options.merge(options)
        type = "#{'date' unless options[:discard_date]}#{'time' unless options[:discard_time]}"
        field_name = "#{options[:name]}[#{name}]"
        if options[:use_select]
          send(:"select_#{type}", current_search[name], options.reverse_merge(include_blank: true, prefix: field_name))
        else
          helper = "#{type}#{'_local' if type == 'datetime'}_field_tag"
          send(helper, field_name, current_search[name], options.except(:name, :object, :use_select).merge(id: "#{options[:id]}_#{name}"))
        end
      end

      def active_scaffold_search_date_field(column, options, current_search, name, ui_options: column.options)
        active_scaffold_search_datetime_field(column, options.merge!(discard_time: true), current_search, name, ui_options: ui_options)
      end

      def active_scaffold_search_time_field(column, options, current_search, name, ui_options: column.options)
        active_scaffold_search_datetime_field(column, options.merge!(discard_date: true), current_search, name, ui_options: ui_options)
      end

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

      def visibles_and_hiddens(search_config, columns = search_config.columns)
        visibles = []
        hiddens = []
        columns.each_column do |column|
          next unless column.respond_to?(:each_column) || column.searchable?

          if search_config.optional_columns.include?(column.name) && !searched_by?(column)
            hiddens << column
          else
            visibles << column
          end
        end
        if active_scaffold_group_column
          group = grouped_search? || search_config.optional_columns.empty? ? visibles : hiddens
          group << active_scaffold_group_column
        end
        [visibles, hiddens]
      end

      def render_field_search_column(column, record)
        column_css_class = column.css_class unless column.css_class.is_a?(Proc)
        if column.respond_to? :each_column
          as_element :field_search_subsection, class: column_css_class do
            render_subsection column, record, nil, :field_search, partial: 'field_search_columns'
          end
        else
          as_element :field_search_element, search_attribute(column, record), class: "form-element #{column_css_class}"
        end
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
