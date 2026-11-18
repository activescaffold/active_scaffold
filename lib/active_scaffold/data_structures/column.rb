# frozen_string_literal: true

require 'active_scaffold/data_structures/column_configuration'

module ActiveScaffold::DataStructures
  class Column
    include ActiveScaffold::Configurable
    include ActiveScaffold::OrmChecks

    NO_PARAMS = Set.new.freeze
    NO_OPTIONS = {}.freeze

    attr_reader :active_record_class
    alias model active_record_class

    # this is the name of the getter on the ActiveRecord model. it is the only absolutely required attribute ... all
    # others will be inferred from this name.
    attr_reader :name

    include ColumnConfiguration

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
    cattr_accessor :associated_limit, instance_accessor: false, default: 3

    # whether the number of associated records must be shown or not
    cattr_accessor :associated_number, instance_accessor: false, default: true

    # whether a blank row must be shown in the subform
    cattr_accessor :show_blank_record, instance_accessor: false, default: true

    # methods for automatic links in singular association columns
    cattr_accessor :actions_for_association_links, instance_accessor: false, default: %i[new edit show]

    cattr_accessor :association_form_ui, instance_accessor: false, default: nil

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
      @db_column = _columns_hash[name.to_s]
      @column = @db_column || model_attribute
      @table = _table_name
      @disable_on_update_column = true
      @db_default_value = ActiveScaffold::OrmChecks.default_value active_record_class, name if @column
      @delegated_association = delegated_association
      @cache_key = [@active_record_class.name, name].compact.join('#')
      setup_association_info
      initialize_association_defaults

      @select_columns = default_select_columns
      @text = default_to_text?
      @number = false
      setup_defaults_for_column if @column

      if @delegated_association
        self.includes = includes ? [{@delegated_association.name => includes}] : [@delegated_association.name]
      end

      initialize_configurable_defaults(name)
    end

    def initialize_association_defaults
      @link = nil
      @autolink = association.present?
      @associated_limit = self.class.associated_limit
      @associated_number = self.class.associated_number
      @show_blank_record = self.class.show_blank_record
      @send_form_on_update_column = self.class.send_form_on_update_column
      @actions_for_association_links = self.class.actions_for_association_links.dup if association
      @allow_add_existing = true
    end

    def initialize_configurable_defaults(name)
      # default all the configurable variables
      self.css_class = ''
      self.sort = true
      self.search_sql = true
      self.logical_search = [name] unless virtual? || association || tableless?
      setup_required
      @weight = estimate_weight
    end
    private :initialize_association_defaults, :initialize_configurable_defaults

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
      ActiveScaffold::OrmChecks.type_for_attribute @active_record_class, @name
    end

    def column_type
      ActiveScaffold::OrmChecks.column_type @active_record_class, @name
    end

    def cast(value)
      ActiveScaffold::OrmChecks.cast @active_record_class, @name, value
    end

    protected

    def setup_defaults_for_column
      if @active_record_class.respond_to?(:defined_enums) && @active_record_class.defined_enums[@name.to_s]
        @form_ui = :select
        @options = {options: @active_record_class.send(@name.to_s.pluralize).keys.map(&:to_sym)}
      elsif column_number?
        @number = true
        @form_ui = :number
        @options = {format: :i18n_number}
      else
        @like_operator = 'LIKE' if use_like_in_postgresql?
        @form_ui =
          case column_type
          when :boolean then null? ? :boolean : :checkbox
          when :text then :textarea
          end
      end
    end

    def use_like_in_postgresql?
      active_record? && @db_column&.collation.present? &&
        @active_record_class.connection.adapter_name.in?(%w[PostgreSQL PostGIS])
    end

    def setup_association_info
      assoc = @active_record_class.reflect_on_association(@name)
      @association =
        if assoc
          if active_record?
            Association::ActiveRecord.new(assoc)
          elsif mongoid?
            Association::Mongoid.new(assoc)
          end
        elsif defined?(ActiveMongoid) && model < ActiveMongoid::Associations
          assoc = @active_record_class.reflect_on_am_association(@name)
          Association::ActiveMongoid.new(assoc) if assoc
        end

      return unless @association

      @form_ui = self.class.association_form_ui
      self.subform_includes = true
      self.includes = [@association.name] if @association&.allow_join?
    end

    def setup_required
      validators_force_require_on = @active_record_class.validators_on(@name)
                                      .map { |val| validator_force_required?(val) }
                                      .compact_blank
      self.required = validators_force_require_on.any?(true) ||
                      validators_force_require_on.reject { |opt| opt == true }.flatten.presence
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
      if @association.nil? && @column
        [field]
      elsif @association&.polymorphic?
        [field, quoted_field(quoted_field_name(@association.foreign_type))]
      elsif @association
        if @association.belongs_to?
          [field]
        else
          columns = []
          if _columns_hash[count_column = "#{@association.name}_count"]
            columns << quoted_field(quoted_field_name(count_column))
          end
          if @association.through_reflection&.belongs_to?
            columns << quoted_field(quoted_field_name(@association.through_reflection.foreign_key))
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

    def default_to_text?
      @column.nil? || [:string, :text, :citext, String].include?(column_type)
    end

    def model_attribute
      return unless active_record?

      name = @name.to_s
      attributes = @active_record_class._default_attributes
      attributes[name] if attributes.key?(name)
    end
  end
end
