module ActiveScaffold::DataStructures
  class Column
    include ActiveScaffold::Configurable

    attr_reader :active_record_class

    # this is the name of the getter on the ActiveRecord model. it is the only absolutely required attribute ... all others will be inferred from this name.
    attr_accessor :name

    # Whether to enable inplace editing for this column. Currently works for text columns, in the List.
    attr_reader :inplace_edit
    def inplace_edit=(value)
      clear_link if value
      @inplace_edit = value
    end

    # :table to refresh list
    # true or :row to refresh row
    attr_accessor :inplace_edit_update

    # Whether this column set is collapsed by default in contexts where collapsing is supported
    attr_accessor :collapsed

    # Whether to enable add_existing for this column
    attr_accessor :allow_add_existing

    # What columns load from main table
    attr_accessor :select_columns

    # Any extra parameters this particular column uses.  This is for create/update purposes.
    def params
      # lazy initialize
      @params ||= Set.new
    end

    # the display-name of the column. this will be used, for instance, as the column title in the table and as the field name in the form.
    # if left alone it will utilize human_attribute_name which includes localization
    attr_writer :label
    def label
      as_(@label) || active_record_class.human_attribute_name(name.to_s)
    end

    # a textual description of the column and its contents. this will be displayed with any associated form input widget, so you may want to consider adding a content example.
    attr_writer :description
    def description
      if @description
        @description
      else
        I18n.t name, :scope => [:activerecord, :description, active_record_class.to_s.underscore.to_sym], :default => ''
      end
    end

    # A placeholder text, to be used inside blank text fields to describe, what should be typed in
    attr_writer :placeholder
    def placeholder
      @placeholder || I18n.t(name, :scope => [:activerecord, :placeholder, active_record_class.to_s.underscore.to_sym], :default => '')
    end

    # this will be /joined/ to the :name for the td's class attribute. useful if you want to style columns on different ActiveScaffolds the same way, but the columns have different names.
    attr_accessor :css_class

    # whether the field is required or not. used on the form for visually indicating the fact to the user.
    # TODO: move into predicate
    attr_writer :required
    def required?
      @required
    end

    attr_reader :update_columns

    # update dependent columns after value change in form
    #  update_columns = :name
    #  update_columns = [:name, :age]
    def update_columns=(column_names)
      @update_columns = Array(column_names)
    end

    # send all the form instead of only new value when this column change
    cattr_accessor :send_form_on_update_column
    attr_accessor :send_form_on_update_column

    # sorting on a column can be configured four ways:
    #   sort = true               default, uses intelligent sorting sql default
    #   sort = false              sometimes sorting doesn't make sense
    #   sort = {:sql => ""}       define your own sql for sorting. this should be result in a sortable value in SQL. ActiveScaffold will handle the ascending/descending.
    #   sort = {:method => ""}    define ruby-side code for sorting. this is SLOW with large recordsets!
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
      @sort
    end

    def sortable?
      sort != false && !sort.nil?
    end

    # a configuration helper for the self.sort property. simply provides a method syntax instead of setter syntax.
    def sort_by(options)
      self.sort = options
    end

    # supported options:
    #   * for association columns
    #     * :select - displays a simple <select> or a collection of checkboxes to (dis)associate records
    def form_ui=(value)
      self.list_method = nil if @list_ui.nil? && value != @form_ui
      @form_ui = value
    end
    attr_reader :form_ui

    def list_ui=(value)
      self.list_method = nil if value != @list_ui
      @list_ui = value
    end

    def list_ui
      @list_ui || form_ui
    end

    attr_writer :show_ui
    def show_ui
      @show_ui || list_ui
    end

    attr_writer :search_ui
    def search_ui
      @search_ui || @form_ui || (@association && !polymorphic_association? ? :select : nil)
    end

    # a place to store dev's column specific options
    attr_accessor :options
    def options
      @options ||= {}
    end

    def link
      @link = @link.call(self) if @link.is_a? Proc
      @link
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

    # set an action_link to nested list or inline form in this column
    def autolink?
      @autolink
    end

    # this should not only delete any existing link but also prevent column links from being automatically added by later routines
    def clear_link
      @link = nil
      @autolink = false
    end

    # define a calculation for the column. anything that ActiveRecord::Calculations::ClassMethods#calculate accepts will do.
    attr_accessor :calculate

    # get whether to run a calculation on this column
    def calculation?
      !(@calculate == false || @calculate.nil?)
    end

    # a collection of associations to pre-load when finding the records on a page
    attr_reader :includes
    def includes=(value)
      @includes = case value
        when Array then value
        else value ? [value] : value # not convert nil to [nil]
      end
    end

    # a collection of associations to do left join when this column is included on search
    def search_joins
      @search_joins || @includes
    end

    def search_joins=(value)
      @search_joins = case value
        when Array then value
        else [value] # automatically convert to an array
      end
    end

    # a collection of columns to load when eager loading is disabled, if it's nil all columns will be loaded
    attr_accessor :select_associated_columns

    # describes how to search on a column
    #   search = true           default, uses intelligent search sql
    #   search = "CONCAT(a, b)" define your own sql for searching. this should be the "left-side" of a WHERE condition. the operator and value will be supplied by ActiveScaffold.
    #   search = [:a, :b]       searches in both fields
    def search_sql=(value)
      @search_sql =
        if value
          (value == true || value.is_a?(Proc)) ? value : Array(value)
        else
          value
        end
    end

    def search_sql
      initialize_search_sql if @search_sql == true
      @search_sql
    end

    def searchable?
      search_sql.present?
    end

    # to modify the default order of columns
    attr_accessor :weight

    # to set how many associated records a column with plural association must show in list
    cattr_accessor :associated_limit
    @@associated_limit = 3
    attr_accessor :associated_limit

    # whether the number of associated records must be shown or not
    cattr_accessor :associated_number
    @@associated_number = true
    attr_writer :associated_number
    def associated_number?
      @associated_number
    end

    # whether a blank row must be shown in the subform
    cattr_accessor :show_blank_record
    @@show_blank_record = true
    attr_writer :show_blank_record
    def show_blank_record?(associated)
      return false unless @show_blank_record
      return false unless association.klass.authorized_for?(:crud_type => :create) && !association.options[:readonly]
      self.plural_association? || (self.singular_association? && associated.blank?)
    end

    # methods for automatic links in singular association columns
    cattr_accessor :actions_for_association_links
    @@actions_for_association_links = [:new, :edit, :show]
    attr_accessor :actions_for_association_links

    cattr_accessor :association_form_ui
    @@association_form_ui = nil

    # ----------------------------------------------------------------- #
    # the below functionality is intended for internal consumption only #
    # ----------------------------------------------------------------- #

    # the ConnectionAdapter::*Column object from the ActiveRecord class
    attr_reader :column

    # the association from the ActiveRecord class
    attr_reader :association
    def singular_association?
      association && !association.collection?
    end

    def plural_association?
      association && association.collection?
    end

    def through_association?
      association && association.options[:through]
    end

    def polymorphic_association?
      association && association.options[:polymorphic]
    end

    def readonly_association?
      return false unless association
      if association.options.key? :readonly
        association.options[:readonly]
      else
        self.through_association?
      end
    end

    # an interpreted property. the column is virtual if it isn't from the active record model or any associated models
    def virtual?
      column.nil? && association.nil?
    end

    attr_writer :number
    def number?
      @number
    end

    def text?
      @text
    end

    # this is so that array.delete and array.include?, etc., will work by column name
    def ==(other) #:nodoc:
      # another column
      if other.respond_to?(:name) && other.class == self.class
        name == other.name.to_sym
      # a string or symbol
      elsif other.respond_to? :to_sym
        name == other.to_sym rescue false # catch "interning empty string"
      # unknown
      else
        self.eql? other
      end
    end

    # instantiation is handled internally through the DataStructures::Columns object
    def initialize(name, active_record_class) #:nodoc:
      self.name = name.to_sym
      @tableless = active_record_class < ActiveScaffold::Tableless
      @column = active_record_class.columns_hash[self.name.to_s]
      @association = active_record_class.reflect_on_association(self.name)
      @autolink = !@association.nil?
      @active_record_class = active_record_class
      @table = active_record_class.table_name
      @associated_limit = self.class.associated_limit
      @associated_number = self.class.associated_number
      @show_blank_record = self.class.show_blank_record
      @send_form_on_update_column = self.class.send_form_on_update_column
      @actions_for_association_links = self.class.actions_for_association_links.clone if @association
      @select_columns = default_select_columns

      @text = @column.nil? || [:string, :text].include?(@column.type)
      if @column
        if active_record_class.respond_to?(:defined_enums) && active_record_class.defined_enums[name.to_s]
          @form_ui = :select
          @options = {:options => active_record_class.send(name.to_s.pluralize).keys}
        elsif @column.number?
          @number = true
          @form_ui = :number
          @options = {:format => :i18n_number}
        else
          @form_ui = case @column.type
            when :boolean then :checkbox
            when :text then :textarea
          end
        end
      end
      @allow_add_existing = true
      @form_ui = self.class.association_form_ui if @association && self.class.association_form_ui

      if association && !polymorphic_association?
        self.includes = [association.name]
        self.search_joins = includes.clone
      end

      # default all the configurable variables
      self.css_class = ''
      self.required = active_record_class.validators_on(self.name).any? do |val|
        validator_force_required?(val)
      end
      self.sort = true
      self.search_sql = true

      @weight = estimate_weight
    end

    # just the field (not table.field)
    def field_name
      return nil if virtual?
      @field_name ||= column ? @active_record_class.connection.quote_column_name(column.name) : association.foreign_key
    end

    def <=>(other)
      order_weight = weight <=> other.weight
      order_weight != 0 ? order_weight : name.to_s <=> other.name.to_s
    end

    def number_to_native(value)
      return value if value.blank? || !value.is_a?(String)
      native = '.' # native ruby separator
      format = {:separator => '', :delimiter => ''}.merge! I18n.t('number.format', :default => {})
      specific = case options[:format]
      when :currency
        I18n.t('number.currency.format', :default => nil)
      when :size
        I18n.t('number.human.format', :default => nil)
      when :percentage
        I18n.t('number.percentage.format', :default => nil)
      end
      format.merge! specific unless specific.nil?
      if format[:separator].blank? || !value.include?(format[:separator]) && value.include?(native) && (format[:delimiter] != native || value !~ /\.\d{3}$/)
        value
      else
        value.gsub(/[^0-9\-#{format[:separator]}]/, '').gsub(format[:separator], native)
      end
    end

    # to cache method to get value in list
    attr_accessor :list_method

    # cache constraints for numeric columns (get in ActiveScaffold::Helpers::FormColumnHelpers::numerical_constraints_for_column)
    attr_accessor :numerical_constraints

    # the table.field name for this column, if applicable
    def field
      @field ||= quoted_field(field_name)
    end

    protected

    def validator_force_required?(val)
      return false if val.options[:if] || val.options[:unless]
      case val
      when ActiveModel::Validations::PresenceValidator
        true
      when ActiveModel::Validations::InclusionValidator
        !val.options[:allow_nil] && !val.options[:allow_blank] &&
          !inclusion_validator_for_checkbox?(val)
      end
    end

    def inclusion_validator_for_checkbox?(val)
      @form_ui == :checkbox &&
        [[true, false], [false, true]].include?(val.options[:with] || val.options[:within] || val.options[:in])
    end

    def default_select_columns
      if association.nil? && column
        [field]
      elsif polymorphic_association?
        [field, quoted_field(@active_record_class.connection.quote_column_name(association.foreign_type))]
      elsif association
        if association.belongs_to?
          [field]
        else
          columns = []
          if active_record_class.columns_hash[count_column = "#{association.name}_count"]
            columns << quoted_field(@active_record_class.connection.quote_column_name(count_column))
          end
          if association.through_reflection.try(:belongs_to?)
            columns << quoted_field(@active_record_class.connection.quote_column_name(association.through_reflection.foreign_key))
          end
          columns
        end
      end
    end

    def quoted_field(name)
      [@active_record_class.quoted_table_name, name].join('.')
    end

    def initialize_sort
      if self.virtual?
        # we don't automatically enable method sorting for virtual columns because it's slow, and we expect fewer complaints this way.
        self.sort = false
      else
        if column && !@tableless
          self.sort = {:sql => field}
        else
          self.sort = false
        end
      end
    end

    def initialize_search_sql
      self.search_sql =
        unless self.virtual?
          if association.nil?
            field.to_s unless @tableless
          elsif !self.polymorphic_association?
            [association.klass.quoted_table_name, association.klass.quoted_primary_key].join('.') unless association.klass < ActiveScaffold::Tableless
          end
        end
    end

    # the table name from the ActiveRecord class
    attr_reader :table

    def estimate_weight
      if singular_association?
        400
      elsif plural_association?
        500
      elsif [:created_at, :updated_at].include?(name)
        600
      elsif [:name, :label, :title].include?(name)
        100
      elsif required?
        200
      else
        300
      end
    end
  end
end
