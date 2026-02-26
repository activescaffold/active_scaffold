# frozen_string_literal: true

module ActiveScaffold::DataStructures
  class Column
    module ProxyableMethods
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

        # define a calculation for the column. anything that ActiveRecord::Calculations::ClassMethods#calculate accepts will do.
        attr_accessor :calculate

        # A placeholder text, to be used inside blank text fields to describe, what should be typed in
        attr_accessor :placeholder

        # this will be /joined/ to the :name for the td's class attribute. useful if you want to style columns on different ActiveScaffolds the same way, but the columns have different names.
        attr_accessor :css_class

        # whether the field is required or not. used on the form for visually indicating the fact to the user.
        attr_writer :required

        # the display-name of the column. this will be used, for instance, as the column title in the table and as the field name in the form.
        # if left alone it will utilize human_attribute_name which includes localization
        attr_writer :label

        # a textual description of the column and its contents. this will be displayed with any associated form input widget, so you may want to consider adding a content example.
        attr_writer :description

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
        # config.columns[:my_column].hide_form_column_if = Proc.new { |record, column, scope| record.vehicle_type == 'tractor' }
        # OR to always hide the column:
        # config.columns[:my_column].hide_form_column_if = true
        # OR to call a method on the record to determine whether to hide the column:
        # config.columns[:my_column].hide_form_column_if = :hide_tractor_fields?
        attr_accessor :hide_form_column_if

        # works like hide_form_column_if, but the form will send an empty value to clear the column when is hidden
        attr_accessor :clear_form_column_if

        # text to display when the column is empty, defaults nil, so list.empty_field_text is used
        attr_accessor :empty_field_text

        # a collection of columns to load from the association when eager loading is disabled, if it's nil all columns will be loaded
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
      end

      def inplace_edit=(value)
        clear_link if value
        @inplace_edit = value
      end

      # this should not only delete any existing link but also prevent column links from being automatically added by later routines
      def clear_link
        @link = nil
        @autolink = false
      end

      # get whether to run a calculation on this column
      def calculation?
        !(calculate == false || calculate.nil?)
      end

      def required?(action = nil)
        if action && @required
          @required == true || @required.include?(action)
        else
          @required
        end
      end

      def placeholder
        @placeholder || I18n.t(name, scope: [:activerecord, :placeholder, active_record_class.to_s.underscore.to_sym], default: '')
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
      #   sort = {sql: ""}       define your own sql for sorting. this should be result in a sortable value in SQL. ActiveScaffold will handle the ascending/descending.
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

        native = '.' # native ruby separator
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
        if format[:separator].blank? || (value.exclude?(format[:separator]) && value.include?(native) && (format[:delimiter] != native || value !~ /\.\d{3}$/))
          value
        else
          value.gsub(/[^0-9\-#{format[:separator]}]/, '').gsub(format[:separator], native)
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
      #   search = "CONCAT(a, b)" define your own sql for searching. this should be the "left-side" of a WHERE condition. the operator and value will be supplied by ActiveScaffold.
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
        @search_sql
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
            {sql: field}
          else
            false
          end
      end

      def initialize_search_sql
        self.search_sql =
          unless virtual?
            if association.nil?
              field.to_s unless tableless?
            elsif association.allow_join?
              [association.quoted_table_name, association.quoted_primary_key].join('.') unless association.klass < ActiveScaffold::Tableless
            end
          end
      end
    end

    include ActiveScaffold::Configurable
    include ActiveScaffold::OrmChecks

    NO_PARAMS = Set.new.freeze
    NO_OPTIONS = {}.freeze

    attr_reader :active_record_class
    alias model active_record_class

    # this is the name of the getter on the ActiveRecord model. it is the only absolutely required attribute ... all others will be inferred from this name.
    attr_reader :name

    include ProxyableMethods

    # Any extra parameters this particular column uses.  This is for create/update purposes.
    def params
      return @params || NO_PARAMS if frozen?

      @params ||= NO_PARAMS.dup
    end

    def default_value
      @default_value || @db_default_value
    end

    def default_value=(value)
      raise ArgumentError, "Can't set default value for non-DB columns (virtual columns or associations)" unless column

      @default_value = value
    end

    def default_value?
      defined? @default_value
    end

    # default to send all the form instead of only new value when a column changes
    cattr_accessor :send_form_on_update_column, instance_accessor: false

    def options
      return @options || NO_OPTIONS if frozen?

      @options ||= NO_OPTIONS.dup
    end

    # set an action_link to nested list or inline form in this column
    def autolink?
      @autolink
    end

    # to set how many associated records a column with plural association must show in list
    cattr_accessor :associated_limit, instance_accessor: false
    @@associated_limit = 3

    # whether the number of associated records must be shown or not
    cattr_accessor :associated_number, instance_accessor: false
    @@associated_number = true

    # whether a blank row must be shown in the subform
    cattr_accessor :show_blank_record, instance_accessor: false
    @@show_blank_record = true

    # methods for automatic links in singular association columns
    cattr_accessor :actions_for_association_links, instance_accessor: false
    @@actions_for_association_links = %i[new edit show]

    cattr_accessor :association_form_ui, instance_accessor: false
    @@association_form_ui = nil

    # ----------------------------------------------------------------- #
    # the below functionality is intended for internal consumption only #
    # ----------------------------------------------------------------- #

    # the ConnectionAdapter::*Column object from the ActiveRecord class
    attr_reader :column

    # the association from the ActiveRecord class
    attr_reader :association

    # the singular association which this column belongs to
    attr_reader :delegated_association

    # an interpreted property. the column is virtual if it isn't from the active record model or any associated models
    def virtual?
      column.nil? && association.nil?
    end

    def text?
      @text
    end

    # this is so that array.delete and array.include?, etc., will work by column name
    def ==(other) # :nodoc:
      # another column
      if other.respond_to?(:name) && (other.class == self.class || other.class == ProxyColumn)
        name == other.name.to_sym
      elsif other.is_a? Symbol
        name == other
      elsif other.is_a? String
        name.to_s == other # avoid creating new symbols
      else # unknown
        eql? other
      end
    end

    # cache key to cache column info
    attr_reader :cache_key

    # instantiation is handled internally through the DataStructures::Columns object
    def initialize(name, active_record_class, delegated_association = nil) # :nodoc:
      @name = name.to_sym
      @active_record_class = active_record_class
      @column = _columns_hash[name.to_s]
      if @column.nil? && active_record? && active_record_class._default_attributes.key?(name.to_s)
        @column = active_record_class._default_attributes[name.to_s]
      end
      @disable_on_update_column = true
      @db_default_value = ActiveScaffold::OrmChecks.default_value active_record_class, name if @column
      @delegated_association = delegated_association
      @cache_key = [@active_record_class.name, name].compact.map(&:to_s).join('#')
      setup_association_info

      @link = nil
      @autolink = association.present?
      @table = _table_name
      @associated_limit = self.class.associated_limit
      @associated_number = self.class.associated_number
      @show_blank_record = self.class.show_blank_record
      @send_form_on_update_column = self.class.send_form_on_update_column
      @actions_for_association_links = self.class.actions_for_association_links.dup if association
      @select_columns = default_select_columns

      @text = @column.nil? || [:string, :text, :citext, String].include?(column_type)
      @number = false
      setup_defaults_for_column if @column
      @allow_add_existing = true
      @form_ui = self.class.association_form_ui if @association && self.class.association_form_ui

      self.includes = [association.name] if association&.allow_join?
      if delegated_association
        self.includes = includes ? [delegated_association.name => includes] : [delegated_association.name]
      end
      self.subform_includes = true if association

      # default all the configurable variables
      self.css_class = ''
      validators_force_require_on = active_record_class.validators_on(name)
                                      .map { |val| validator_force_required?(val) }
                                      .compact_blank
      self.required = validators_force_require_on.any?(true) ||
                      validators_force_require_on.reject { |opt| opt == true }.flatten.presence
      self.sort = true
      self.search_sql = true
      self.logical_search = [name] unless virtual? || association || tableless?

      @weight = estimate_weight
    end

    # just the field (not table.field)
    def field_name
      return nil if virtual?

      @field_name ||= column ? quoted_field_name(column.name) : quoted_field_name(association.foreign_key)
    end

    def default_for_empty_value
      return nil unless column

      if column.is_a?(ActiveModel::Attribute)
        column.value
      elsif active_record? && null?
        nil
      else
        @db_default_value
      end
    end

    def null?
      if active_record? && !column.is_a?(ActiveModel::Attribute)
        column&.null
      else
        true
      end
    end

    # the table.field name for this column, if applicable
    def field
      @field ||= quoted_field(field_name)
    end

    def group_by=(value)
      @group_by = value ? Array(value) : nil
    end

    def group_by
      @group_by || select_columns || [field]
    end

    attr_writer :grouped_select

    def grouped_select
      Arel.sql(@grouped_select&.to_s || field)
    end

    def quoted_foreign_type
      quoted_field(quoted_field_name(association.foreign_type))
    end

    def type_for_attribute
      ActiveScaffold::OrmChecks.type_for_attribute active_record_class, name
    end

    def column_type
      ActiveScaffold::OrmChecks.column_type active_record_class, name
    end

    def cast(value)
      ActiveScaffold::OrmChecks.cast active_record_class, name, value
    end

    protected

    def setup_defaults_for_column
      if active_record_class.respond_to?(:defined_enums) && active_record_class.defined_enums[name.to_s]
        @form_ui = :select
        @options = {options: active_record_class.send(name.to_s.pluralize).keys.map(&:to_sym)}
      elsif column_number?
        @number = true
        @form_ui = :number
        @options = {format: :i18n_number}
      else
        @form_ui =
          case column_type
          when :boolean then null? ? :boolean : :checkbox
          when :text then :textarea
          end
      end
    end

    def setup_association_info
      assoc = active_record_class.reflect_on_association(name)
      @association =
        if assoc
          if active_record?
            Association::ActiveRecord.new(assoc)
          elsif mongoid?
            Association::Mongoid.new(assoc)
          end
        elsif defined?(ActiveMongoid) && model < ActiveMongoid::Associations
          assoc = active_record_class.reflect_on_am_association(name)
          Association::ActiveMongoid.new(assoc) if assoc
        end
    end

    def validator_force_required?(val)
      return false if val.options[:if] || val.options[:unless]

      case val
      when ActiveModel::Validations::PresenceValidator
        validator_required_on(val)
      when ActiveModel::Validations::InclusionValidator
        if !val.options[:allow_nil] && !val.options[:allow_blank] && !inclusion_validator_for_checkbox?(val)
          validator_required_on(val)
        end
      end
    end

    def validator_required_on(val)
      val.options[:on] ? Array(val.options[:on]) : true
    end

    def inclusion_validator_for_checkbox?(val)
      @form_ui == :checkbox &&
        [[true, false], [false, true]].include?(val.options[:with] || val.options[:within] || val.options[:in])
    end

    def default_select_columns
      if association.nil? && column
        [field]
      elsif association&.polymorphic?
        [field, quoted_field(quoted_field_name(association.foreign_type))]
      elsif association
        if association.belongs_to?
          [field]
        else
          columns = []
          if _columns_hash[count_column = "#{association.name}_count"]
            columns << quoted_field(quoted_field_name(count_column))
          end
          if association.through_reflection&.belongs_to?
            columns << quoted_field(quoted_field_name(association.through_reflection.foreign_key))
          end
          columns
        end
      end
    end

    def column_number?
      if active_record?
        %i[float decimal integer].include? column_type
      elsif mongoid?
        @column.type < Numeric
      end
    end

    def quoted_field_name(column_name)
      if active_record?
        @active_record_class.connection.quote_column_name(column_name)
      else
        column_name.to_s
      end
    end

    def quoted_field(name)
      active_record? ? [_quoted_table_name, name].compact.join('.') : name
    end

    # the table name from the ActiveRecord class
    attr_reader :table

    def estimate_weight
      if association&.singular?
        400
      elsif association&.collection?
        500
      elsif %i[created_at updated_at].include?(name)
        600
      elsif %i[name label title].include?(name)
        100
      elsif required?
        200
      else
        300
      end
    end

    def check_valid_action_ui_params(value)
      return true if valid_action_ui_params?(value)

      raise ArgumentError, 'value must be a Symbol, or an array of Symbol and Hash'
    end

    def valid_action_ui_params?(value)
      if value.is_a?(Array)
        value.size <= 2 && valid_form_ui?(value[0]) && (value[1].nil? || value[1].is_a?(Hash))
      else
        valid_form_ui?(value)
      end
    end

    def valid_form_ui?(value)
      value.nil? || value.is_a?(Symbol)
    end
  end
end
