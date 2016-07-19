module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module SearchColumnHelpers
      # This method decides which input to use for the given column.
      # It does not do any rendering. It only decides which method is responsible for rendering.
      def active_scaffold_search_for(column, options = nil)
        options ||= active_scaffold_search_options(column)
        record = options[:object]
        ActiveSupport::Deprecation.warn 'Relying on @record is deprecated, include :object in options with record.', caller if record.nil? # TODO: Remove when relying on @record is removed
        record ||= @record # TODO: Remove when relying on @record is removed

        # first, check if the dev has created an override for this specific field for search
        if (method = override_search_field(column))
          send(method, record, options)

        # second, check if the dev has specified a valid search_ui for this column, using specific ui for searches
        elsif column.search_ui && (method = override_search(column.search_ui))
          send(method, column, options)

        # third, check if the dev has specified a valid search_ui for this column, using generic ui for forms
        elsif column.search_ui && (method = override_input(column.search_ui))
          send(method, column, options)

        # fourth, check if the dev has created an override for this specific field
        elsif (method = override_form_field(column))
          send(method, record, options)

        # fallback: we get to make the decision
        else
          if column.association || column.virtual?
            active_scaffold_search_text(column, options)

          else # regular model attribute column
            # if we (or someone else) have created a custom render option for the column type, use that
            if (method = override_search(column.column.type))
              send(method, column, options)
            # if we (or someone else) have created a custom render option for the column type, use that
            elsif (method = override_input(column.column.type))
              send(method, column, options)
            # final ultimate fallback: use rails' generic input method
            else
              # for textual fields we pass different options
              text_types = [:text, :string, :integer, :float, :decimal]
              options = active_scaffold_input_text_options(options) if text_types.include?(column.column.type)
              text_field(:record, column.name, options.merge(column.options))
            end
          end
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
        field = active_scaffold_search_for column, column_options
        %(<dl><dt>#{label_tag search_label_for(column, column_options), search_column_label(column, record)}</dt><dd>#{field}</dd></dl>).html_safe
      end

      def search_label_for(column, options)
        options[:id] unless [:range, :integer, :decimal, :float, :string, :date_picker, :datetime_picker, :calendar_date_select].include? column.search_ui
      end

      ##
      ## Search input methods
      ##

      def active_scaffold_search_multi_select(column, options)
        record = options.delete(:object)
        ActiveSupport::Deprecation.warn 'Relying on @record is deprecated, include :object in options with record.', caller if record.nil? # TODO: Remove when relying on @record is removed
        record ||= @record # TODO: Remove when relying on @record is removed
        associated = options.delete :value
        associated = [associated].compact unless associated.is_a? Array

        if column.association
          associated.collect!(&:to_i)
          method = column.options[:label_method] || :to_label
          select_options = sorted_association_options_find(column.association, nil, record).collect do |r|
            [r.send(method), r.id]
          end
        else
          select_options = column.options[:options].collect do |text, value|
            active_scaffold_translated_option(column, text, value)
          end
        end
        return as_(:no_options) if select_options.empty?

        active_scaffold_checkbox_list(column, select_options, associated, options)
      end

      def active_scaffold_search_select(column, html_options, options = {})
        record = html_options.delete(:object)
        ActiveSupport::Deprecation.warn 'Relying on @record is deprecated, include :object in html_options with record.', caller if record.nil? # TODO: Remove when relying on @record is removed
        record ||= @record # TODO: Remove when relying on @record is removed
        associated = html_options.delete :value
        if column.association
          associated = associated.is_a?(Array) ? associated.map(&:to_i) : associated.to_i unless associated.nil?
          method = column.association.macro == :belongs_to ? column.association.foreign_key : column.name
          select_options = sorted_association_options_find(column.association, false, record)
        else
          method = column.name
          select_options = active_scaffold_enum_options(column, record).collect do |text, value|
            active_scaffold_translated_option(column, text, value)
          end
        end

        options = options.merge(:selected => associated).merge column.options
        html_options.merge! column.options[:html_options] || {}
        if html_options[:multiple]
          html_options[:name] += '[]'
        else
          options[:include_blank] ||= as_(:_select_)
          active_scaffold_translate_select_options(options)
        end

        if (optgroup = options.delete(:optgroup))
          select(:record, method, active_scaffold_grouped_options(column, select_options, optgroup), options, html_options)
        elsif column.association
          collection_select(:record, method, select_options, :id, column.options[:label_method] || :to_label, options, html_options)
        else
          select(:record, method, select_options, options, html_options)
        end
      end

      def active_scaffold_search_text(column, options)
        text_field :record, column.name, active_scaffold_input_text_options(options)
      end

      # we can't use active_scaffold_input_boolean because we need to have a nil value even when column can't be null
      # to decide whether search for this field or not
      def active_scaffold_search_boolean(column, options)
        select_options = []
        select_options << [as_(:_select_), nil]
        select_options << [as_(:true), true]
        select_options << [as_(:false), false]

        select_tag(options[:name], options_for_select(select_options, ActiveScaffold::Core.column_type_cast(options[:value], column.column)), :id => options[:id])
      end
      # we can't use checkbox ui because it's not possible to decide whether search for this field or not
      alias_method :active_scaffold_search_checkbox, :active_scaffold_search_boolean

      def active_scaffold_search_null(column, options)
        select_options = []
        select_options << [as_(:_select_), nil]
        select_options.concat ActiveScaffold::Finder::NULL_COMPARATORS.collect { |comp| [as_(comp), comp] }
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

      def active_scaffold_search_range_comparator_options(column)
        select_options = ActiveScaffold::Finder::NUMERIC_COMPARATORS.collect { |comp| [as_(comp.downcase.to_sym), comp] }
        if active_scaffold_search_range_string?(column)
          select_options.unshift *ActiveScaffold::Finder::STRING_COMPARATORS.collect { |title, comp| [as_(title), comp] }
        end
        if include_null_comparators? column
          select_options += ActiveScaffold::Finder::NULL_COMPARATORS.collect { |comp| [as_(comp), comp] }
        end
        select_options
      end

      def include_null_comparators?(column)
        return column.options[:null_comparators] if column.options.key? :null_comparators
        if column.association
          column.association.macro != :belongs_to || active_scaffold_config.columns[column.association.foreign_key].column.try(:null)
        else
          column.column.try(:null)
        end
      end

      def active_scaffold_search_range(column, options)
        opt_value, from_value, to_value = field_search_params_range_values(column)

        select_options = active_scaffold_search_range_comparator_options(column)
        if active_scaffold_search_range_string?(column)
          text_field_size = 15
        else
          text_field_size = 10
        end
        opt_value ||= select_options[0][1]

        from_value = controller.class.condition_value_for_numeric(column, from_value)
        to_value = controller.class.condition_value_for_numeric(column, to_value)
        from_value = format_number_value(from_value, column.options) if from_value.is_a?(Numeric)
        to_value = format_number_value(to_value, column.options) if to_value.is_a?(Numeric)
        html = select_tag("#{options[:name]}[opt]", options_for_select(select_options, opt_value),
                          :id => "#{options[:id]}_opt", :class => 'as_search_range_option')
        html << content_tag('span', :id => "#{options[:id]}_numeric", :style => ActiveScaffold::Finder::NULL_COMPARATORS.include?(opt_value) ? 'display: none' : nil) do
          text_field_tag("#{options[:name]}[from]", from_value, active_scaffold_input_text_options(:id => options[:id], :size => text_field_size)) <<
            content_tag(
              :span, (
                ' - ' + text_field_tag("#{options[:name]}[to]", to_value,
                                       active_scaffold_input_text_options(:id => "#{options[:id]}_to", :size => text_field_size))
              ).html_safe,
              :id => "#{options[:id]}_between", :class => 'as_search_range_between', :style => (opt_value == 'BETWEEN') ? nil : 'display: none'
            )
        end
        content_tag :span, html, :class => 'search_range'
      end
      alias_method :active_scaffold_search_integer, :active_scaffold_search_range
      alias_method :active_scaffold_search_decimal, :active_scaffold_search_range
      alias_method :active_scaffold_search_float, :active_scaffold_search_range
      alias_method :active_scaffold_search_string, :active_scaffold_search_range

      def field_search_datetime_value(value)
        DateTime.new(value[:year].to_i, value[:month].to_i, value[:day].to_i, value[:hour].to_i, value[:minute].to_i, value[:second].to_i) unless value.nil? || value[:year].blank?
      end

      def active_scaffold_search_datetime(column, options)
        _, from_value, to_value = field_search_params_range_values(column)
        options = column.options.merge(options)
        helper = "select_#{'date' unless options[:discard_date]}#{'time' unless options[:discard_time]}"

        send(helper, field_search_datetime_value(from_value), {:include_blank => true, :prefix => "#{options[:name]}[from]"}.merge(options)) <<
          ' - '.html_safe << send(helper, field_search_datetime_value(to_value), {:include_blank => true, :prefix => "#{options[:name]}[to]"}.merge(options))
      end

      def active_scaffold_search_date(column, options)
        active_scaffold_search_datetime(column, options.merge!(:discard_time => true))
      end

      def active_scaffold_search_time(column, options)
        active_scaffold_search_datetime(column, options.merge!(:discard_date => true))
      end
      alias_method :active_scaffold_search_timestamp, :active_scaffold_search_datetime

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
        search_config.columns.each do |column|
          next unless column.search_sql
          if search_config.optional_columns.include?(column.name) && !searched_by?(column)
            hiddens << column
          else
            visibles << column
          end
        end
        [visibles, hiddens]
      end

      def searched_by?(column)
        value = field_search_params[column.name]
        case value
        when Hash
          !value['from'].blank?
        when String
          !value.blank?
        else
          false
        end
      end
    end
  end
end
