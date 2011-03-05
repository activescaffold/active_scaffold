module ActiveScaffold
  module Helpers
    # Helpers that assist with the rendering of a Form Column
    module SearchColumnHelpers
      # This method decides which input to use for the given column.
      # It does not do any rendering. It only decides which method is responsible for rendering.
      def active_scaffold_search_for(column)
        options = active_scaffold_search_options(column)

        # first, check if the dev has created an override for this specific field for search
        if override_search_field?(column)
          send(override_search_field(column), @record, options)

        # second, check if the dev has specified a valid search_ui for this column, using specific ui for searches
        elsif column.search_ui and override_search?(column.search_ui)
          send(override_search(column.search_ui), column, options)

        # third, check if the dev has specified a valid search_ui for this column, using generic ui for forms
        elsif column.search_ui and override_input?(column.search_ui)
          send(override_input(column.search_ui), column, options)

        # fourth, check if the dev has created an override for this specific field
        elsif override_form_field?(column)
          send(override_form_field(column), @record, options)

        # fallback: we get to make the decision
        else
          if column.association or column.virtual?
            active_scaffold_search_text(column, options)

          else # regular model attribute column
            # if we (or someone else) have created a custom render option for the column type, use that
            if override_search?(column.column.type)
              send(override_search(column.column.type), column, options)
            # if we (or someone else) have created a custom render option for the column type, use that
            elsif override_input?(column.column.type)
              send(override_input(column.column.type), column, options)
            # final ultimate fallback: use rails' generic input method
            else
              # for textual fields we pass different options
              text_types = [:text, :string, :integer, :float, :decimal]
              options = active_scaffold_input_text_options(options) if text_types.include?(column.column.type)
              text_field(:record, column.name, options.merge(column.options))
            end
          end
        end
      end

      # the standard active scaffold options used for class, name and scope
      def active_scaffold_search_options(column)
        { :name => "search[#{column.name}]", :class => "#{column.name}-input", :id => "search_#{column.name}", :value => field_search_params[column.name] }
      end

      ##
      ## Search input methods
      ##

      def active_scaffold_search_multi_select(column, options)
        associated = options.delete :value
        associated = [associated].compact unless associated.is_a? Array
        associated.collect!(&:to_i)
        
        if column.association
          select_options = options_for_association(column.association, false)
        else
          select_options = Array(column.options[:options])
        end
        return as_(:no_options) if select_options.empty?

        active_scaffold_checkbox_list(column, select_options, associated, options)
      end

      def active_scaffold_search_select(column, html_options)
        associated = html_options.delete :value
        if column.association
          associated = associated.is_a?(Array) ? associated.map(&:to_i) : associated.to_i unless associated.nil?
          method = column.association.macro == :belongs_to ? column.association.primary_key_name : column.name
          select_options = options_for_association(column.association, true)
        else
          method = column.name
          select_options = Array(column.options[:options])
        end

        options = { :selected => associated }.merge! column.options
        html_options.merge! column.options[:html_options] || {}
        if html_options[:multiple]
          html_options[:name] += '[]'
        else
          options[:include_blank] ||= as_(:_select_) 
        end
        select(:record, method, select_options, options, html_options)
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

        select_tag(options[:name], options_for_select(select_options, column.column.type_cast(field_search_params[column.name])))
      end
      # we can't use checkbox ui because it's not possible to decide whether search for this field or not
      alias_method :active_scaffold_search_checkbox, :active_scaffold_search_boolean
      
      def active_scaffold_search_null(column, options)
        select_options = []
        select_options << [as_(:_select_), nil]
        select_options.concat ActiveScaffold::Finder::NullComparators.collect {|comp| [as_(comp), comp]}
        select_tag(options[:name], options_for_select(select_options, field_search_params[column.name]))
      end

      def field_search_params_range_values(column)
        values = field_search_params[column.name]
        return nil if values.nil?
        return values[:opt], (values[:from].blank? ? nil : values[:from]), (values[:to].blank? ? nil : values[:to])
        
      end

      def active_scaffold_search_range_comparator_options(column)
        select_options = ActiveScaffold::Finder::NumericComparators.collect {|comp| [as_(comp.downcase.to_sym), comp]}
        if column.column && column.column.text?
          select_options.unshift *ActiveScaffold::Finder::StringComparators.collect {|title, comp| [as_(title), comp]}
        end
        select_options
      end

      def active_scaffold_search_range(column, options)
        opt_value, from_value, to_value = field_search_params_range_values(column)
        
        select_options = active_scaffold_search_range_comparator_options(column)
        text_field_size = ((column.column && column.column.text?) ? 15 : 10)

        from_value = controller.class.condition_value_for_numeric(column, from_value)
        to_value = controller.class.condition_value_for_numeric(column, to_value)
        from_value = format_number_value(from_value, column.options) if from_value.is_a?(Numeric)
        to_value = format_number_value(to_value, column.options) if to_value.is_a?(Numeric)
        html = select_tag("#{options[:name]}[opt]",
              options_for_select(select_options, opt_value),
              :id => "#{options[:id]}_opt",
              :class => "as_search_range_option")
        html << ' ' << text_field_tag("#{options[:name]}[from]", from_value, active_scaffold_input_text_options(:id => options[:id], :size => text_field_size))
        html << ' ' << content_tag(:span, (' - ' + text_field_tag("#{options[:name]}[to]", to_value,
              active_scaffold_input_text_options(:id => "#{options[:id]}_to", :size => text_field_size))).html_safe,
              :id => "#{options[:id]}_between", :class => "as_search_range_between", :style => "display:#{(opt_value == 'BETWEEN') ? '' : 'none'}")
        html
      end
      alias_method :active_scaffold_search_integer, :active_scaffold_search_range
      alias_method :active_scaffold_search_decimal, :active_scaffold_search_range
      alias_method :active_scaffold_search_float, :active_scaffold_search_range
      alias_method :active_scaffold_search_string, :active_scaffold_search_range

      def active_scaffold_search_record_select(column, options)
        value = field_search_record_select_value(column)
        active_scaffold_record_select(column, options, value, column.options[:multiple])
      end
      
      def field_search_record_select_value(column)
        begin 
          value = field_search_params[column.name]
          unless value.blank?
            if column.options[:multiple]
              column.association.klass.find value.collect!(&:to_i)
            else
              column.association.klass.find(value.to_i)
            end
          end
        rescue Exception => e
          logger.error Time.now.to_s + "Sorry, we are not that smart yet. Attempted to restore search values to search fields but instead got -- #{e.inspect} -- on the ActiveScaffold column = :#{column.name} in #{controller.class}"
          raise e
        end
      end

      def field_search_datetime_value(value)
        DateTime.new(value[:year].to_i, value[:month].to_i, value[:day].to_i, value[:hour].to_i, value[:minute].to_i, value[:second].to_i) unless value.nil? || value[:year].blank?
      end
      
      def active_scaffold_search_datetime(column, options)
        opt_value, from_value, to_value = field_search_params_range_values(column)
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

      def override_search_field?(column)
        respond_to?(override_search_field(column))
      end

      # the naming convention for overriding form fields with helpers
      def override_search_field(column)
        "#{column.name}_search_column"
      end

      def override_search?(search_ui)
        respond_to?(override_search(search_ui))
      end

      # the naming convention for overriding search input types with helpers
      def override_search(form_ui)
        "active_scaffold_search_#{form_ui}"
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
        return visibles, hiddens
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
