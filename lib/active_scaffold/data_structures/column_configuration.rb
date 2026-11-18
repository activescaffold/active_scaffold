# frozen_string_literal: true

module ActiveScaffold::DataStructures
  module ColumnConfiguration
    extend ActiveSupport::Concern

    included do # rubocop:disable Metrics/BlockLength
      # Whether to enable inplace editing for this column. Currently works for text columns, in the List.
      attr_reader :inplace_edit

      # :table to refresh list
      # true or :row to refresh row
      attr_accessor :inplace_edit_update

      # Whether this column set is collapsed by default in contexts where collapsing is supported
      attr_accessor :collapsed

      # Whether to enable add_existing for this column
      attr_accessor :allow_add_existing

      # What columns load from main table
      attr_accessor :select_columns

      # define a calculation for the column. anything that ActiveRecord::Calculations::ClassMethods#calculate accepts
      # will do.
      attr_accessor :calculate

      # A placeholder text, to be used inside blank text fields to describe, what should be typed in
      attr_accessor :placeholder

      # this will be /joined/ to the :name for the td's class attribute. useful if you want to style columns on
      # different ActiveScaffolds the same way, but the columns have different names.
      attr_accessor :css_class

      # whether the field is required or not. used on the form for visually indicating the fact to the user.
      attr_writer :required

      # the display-name of the column. this will be used, for instance, as the column title in the table and as the
      # field name in the form.
      # if left alone it will utilize human_attribute_name which includes localization
      attr_writer :label

      # a textual description of the column and its contents. this will be displayed with any associated form input
      # widget, so you may want to consider adding a content example.
      attr_writer :description

      # enable it if local sorting shouldn't be used for this column at all
      attr_writer :skip_local_sorting

      attr_reader :update_columns

      # send all the form instead of only new value when this column changes
      attr_accessor :send_form_on_update_column

      # disable the form while the request to refresh other columns is sent
      attr_accessor :disable_on_update_column

      # add a custom attr_accessor that can contain a Proc (or boolean or symbol)
      # that will be called when the column renders, such that we can dynamically
      # hide or show the column with an element that can be replaced by
      # update_columns, but won't affect the form submission.
      # The value can be set in the scaffold controller as follows to dynamically
      # hide the column based on a Proc's output:
      # config.columns[:my_column].hide_form_column_if = Proc.new { |record, column, scope| record.vehicle_type ==
      # 'tractor' }
      # OR to always hide the column:
      # config.columns[:my_column].hide_form_column_if = true
      # OR to call a method on the record to determine whether to hide the column:
      # config.columns[:my_column].hide_form_column_if = :hide_tractor_fields?
      attr_accessor :hide_form_column_if

      # works like hide_form_column_if, but the form will send an empty value to clear the column when is hidden
      attr_accessor :clear_form_column_if

      # text to display when the column is empty, defaults nil, so list.empty_field_text is used
      attr_accessor :empty_field_text

      # a collection of columns to load from the association when eager loading is disabled, if it's nil all columns
      # will be loaded
      attr_accessor :select_associated_columns

      # to modify the default order of columns
      attr_accessor :weight

      attr_accessor :associated_limit

      attr_writer :associated_number

      # what string to use to join records from plural associations
      attr_accessor :association_join_text

      attr_writer :show_blank_record

      attr_accessor :actions_for_association_links

      attr_writer :number

      # supported options:
      #   * for association columns
      #     * :select - displays a simple <select> or a collection of checkboxes to (dis)associate records
      attr_reader :form_ui

      attr_reader :form_ui_options

      # a collection of associations to pre-load when finding the records on a page
      attr_reader :includes

      # a collection of associations to pre-load when the column is used as a subform,
      # defaults to true, which means get associations from subform columns in the associated controller
      # set to any other value to avoid checking the associated controller, false or nil to prevent preloading
      attr_reader :subform_includes

      # a place to store dev's column specific options
      attr_writer :options

      # define the fields to use with logical search
      attr_accessor :logical_search

      # SQL operator used for text searches. Defaults according to the adapter when nil.
      attr_accessor :like_operator
    end

    def inplace_edit=(value)
      clear_link if value
      @inplace_edit = value
    end

    # this should not only delete any existing link but also prevent column links from being automatically added by
    # later routines
    def clear_link
      @link = nil
      @autolink = false
    end

    # get whether to run a calculation on this column
    def calculation?
      !(calculate == false || calculate.nil?)
    end

    # if local sorting shouldn't be used for this column at all
    def skip_local_sorting?
      @skip_local_sorting == true
    end

    def required?(action = nil)
      if action && @required
        @required == true || @required.include?(action)
      else
        @required
      end
    end

    def placeholder
      @placeholder || I18n.t(name, scope: [:activerecord, :placeholder, active_record_class.to_s.underscore.to_sym],
                                   default: '')
    end

    def label(record = nil, scope = nil)
      label =
        if @label.respond_to?(:call)
          # sometimes label is called without a record in context (ie, from table
          # headers).  In this case fall back to the default instead of the Proc.
          @label.call(record, self, scope) if record
        elsif @label
          as_(@label)
        end
      label || active_record_class.human_attribute_name(name.to_s)
    end

    def description(record = nil, scope = nil)
      if @description.respond_to?(:call)
        @description.call(record, self, scope)
      elsif @description
        @description
      else
        I18n.t name, scope: [:activerecord, :description, active_record_class.to_s.underscore.to_sym], default: ''
      end
    end

    # update dependent columns after value change in form
    #  update_columns = :name
    #  update_columns = [:name, :age]
    def update_columns=(column_names)
      @update_columns = column_names.is_a?(Array) ? column_names : [column_names]
    end

    # sorting on a column can be configured four ways:
    #   sort = true               default, uses intelligent sorting sql default
    #   sort = false              sometimes sorting doesn't make sense
    #   sort = {sql: ""}       define your own sql for sorting. this should be result in a sortable value in SQL.
    #   ActiveScaffold will handle the ascending/descending.
    #   sort = {method: ""}    define ruby-side code for sorting. this is SLOW with large recordsets!
    def sort=(value)
      if value.is_a? Hash
        value.assert_valid_keys(:sql, :method)
        @sort = value
      else
        @sort = value ? true : false # force true or false
      end
    end

    def sort
      initialize_sort if @sort == true
      @sort if @sort
    end

    def sortable?
      sort != false && !sort.nil?
    end

    # a configuration helper for the self.sort property. simply provides a method syntax instead of setter syntax.
    def sort_by(options)
      self.sort = options
    end

    # a collection of associations to do left join when the list is sorted by this column
    def sort_joins
      @sort_joins || includes
    end

    def sort_joins=(value)
      @sort_joins =
        case value
        when Array then value
        else [value] # automatically convert to an array
        end
    end

    def associated_number?
      @associated_number
    end

    def show_blank_record?(associated)
      return false unless @show_blank_record
      return false unless association.klass.authorized_for?(crud_type: :create) && !association.readonly?

      association.collection? || (association.singular? && associated.blank?)
    end

    def number?
      @number
    end

    def <=>(other)
      order_weight = weight <=> other.weight
      order_weight.nonzero? ? order_weight : name.to_s <=> other.name.to_s
    end

    def convert_to_native?
      number? && options[:format] && form_ui != :number
    end

    def number_to_native(value)
      return value if value.blank? || !value.is_a?(String)

      format = number_format
      if format[:separator].blank? || uses_native_separator?(value, format)
        value
      else
        value.gsub(/[^0-9\-#{format[:separator]}]/, '').gsub(format[:separator], '.')
      end
    end

    # value must be a Symbol, or an Array of form_ui and options hash which will be used with form_ui only
    def form_ui=(value)
      check_valid_action_ui_params(value)
      @form_ui, @form_ui_options = *value
    end

    # value must be a Symbol, or an Array of list_ui and options hash which will be used with list_ui only
    def list_ui=(value)
      check_valid_action_ui_params(value)
      @list_ui, @list_ui_options = *value
    end

    def list_ui
      @list_ui || form_ui
    end

    def list_ui_options
      @list_ui ? @list_ui_options : form_ui_options
    end

    # value must be a Symbol, or an Array of show_ui and options hash which will be used with show_ui only
    def show_ui=(value)
      check_valid_action_ui_params(value)
      @show_ui, @show_ui_options = *value
    end

    def show_ui
      @show_ui || list_ui
    end

    def show_ui_options
      @show_ui ? @show_ui_options : list_ui_options
    end

    # value must be a Symbol, or an Array of search_ui and options hash which will be used with search_ui only
    def search_ui=(value)
      check_valid_action_ui_params(value)
      @search_ui, @search_ui_options = *value
    end

    def search_ui
      @search_ui || form_ui || (:select if association && !association.polymorphic?)
    end

    def search_ui_options
      @search_ui ? @search_ui_options : form_ui_options
    end

    def includes=(value)
      @includes =
        case value
        when Array then value
        else value ? [value] : value # not convert nil to [nil]
        end
    end

    def subform_includes=(value)
      @subform_includes =
        case value
        when Array, TrueClass then value
        else value ? [value] : value # not convert nil to [nil]
        end
    end

    # a collection of associations to do left join when this column is included on search
    def search_joins
      @search_joins || includes
    end

    def search_joins=(value)
      @search_joins =
        case value
        when Array then value
        else [value] # automatically convert to an array
        end
    end

    # describes how to search on a column
    #   search = true           default, uses intelligent search sql
    #   search = "CONCAT(a, b)" define your own sql for searching. this should be the "left-side" of a WHERE
    #   condition. the operator and value will be supplied by ActiveScaffold.
    #   search = [:a, :b]       searches in both fields
    def search_sql=(value)
      @search_sql =
        if value
          value == true || value.is_a?(Proc) ? value : Array(value)
        else
          value
        end
    end

    def search_sql
      initialize_search_sql if @search_sql == true
      return @search_sql unless @search_sql.is_a?(Array) && active_record?

      connection = active_record_class.connection
      @search_sql.map do |sql|
        next sql unless sql.is_a?(Symbol)

        "#{connection.quote_table_name(active_record_class.table_name)}.#{connection.quote_column_name(sql)}"
      end
    end

    def searchable?
      search_sql.present? || (logical_search.present? && ActiveScaffold::Finder.logical_comparators.present?)
    end

    def link
      if frozen? && @link.is_a?(Proc)
        ActiveScaffold::Registry.cache(:column_links, cache_key) { @link.call(self).deep_freeze! }
      else
        @link = @link.call(self) if @link.is_a? Proc
        @link
      end
    end

    # associate an action_link with this column
    def set_link(action, options = {})
      if action.is_a?(ActiveScaffold::DataStructures::ActionLink) || (action.is_a? Proc)
        @link = action
      else
        options[:label] ||= label
        options[:position] ||= :after unless options.key?(:position)
        options[:type] ||= :member
        @link = ActiveScaffold::DataStructures::ActionLink.new(action, options)
      end
    end

    def cache_count?
      includes.blank? && associated_number? && association&.cache_count?
    end

    def attributes=(opts)
      opts.each do |setting, value|
        send :"#{setting}=", value
      end
    end

    protected

    def initialize_sort
      self.sort =
        if column && !tableless?
          {sql: name}
        else
          false
        end
    end

    def initialize_search_sql
      self.search_sql =
        unless virtual?
          if association.nil?
            name unless tableless?
          elsif association.allow_join?
            [association.quoted_table_name, association.quoted_primary_key].join('.') unless association.klass < ActiveScaffold::Tableless
          end
        end
    end

    def number_format
      format = {separator: '', delimiter: ''}.merge! I18n.t('number.format', default: {})
      specific =
        case options[:format]
        when :currency
          I18n.t('number.currency.format', default: nil)
        when :size
          I18n.t('number.human.format', default: nil)
        when :percentage
          I18n.t('number.percentage.format', default: nil)
        end
      format.merge! specific unless specific.nil?
      format
    end

    def uses_native_separator?(number, format)
      number.exclude?(format[:separator]) && number.include?('.') &&
        (format[:delimiter] != '.' || number !~ /\.\d{3}$/)
    end
  end
end
