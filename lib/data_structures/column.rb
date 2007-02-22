module ActiveScaffold::DataStructures
  class Column
    include ActiveScaffold::Configurable

    # this is the name of the getter on the ActiveRecord model. it is the only absolutely required attribute ... all others will be inferred from this name.
    attr_accessor :name

    # the display-name of the column. this will be used, for instance, as the column title in the table and as the field name in the form.
    attr_accessor :label

    # a textual description of the column and its contents. this will be displayed with any associated form input widget, so you may want to consider adding a content example.
    attr_accessor :description

    # this will be /joined/ to the :name for the td's class attribute. useful if you want to style columns on different ActiveScaffolds the same way, but the columns have different names.
    attr_accessor :css_class

    # whether the field is required or not. used on the form for visually indicating the fact to the user.
    # TODO: move into predicate
    attr_writer :required
    def required?
      @required
    end

    # sorting on a column can be configured four ways:
    #   sort = true               default, uses intelligent sorting sql default
    #   sort = false              sometimes sorting doesn't make sense
    #   sort = {:sql => ""}       define your own sql for sorting. this should be result in a sortable value in SQL. ActiveScaffold will handle the ascending/descending.
    #   sort = {:method => ""}    define ruby-side code for sorting. this is SLOW with large recordsets!
    attr_writer :sort
    def sort
      self.initialize_sort if @sort === true
      @sort
    end
    def sortable?
      sort != false && !sort.nil?
    end
    # a configuration helper for the self.sort property. simply provides a method syntax instead of setter syntax.
    def sort_by(options)
      if options
        if options.is_a? Hash
          options.assert_valid_keys(:sql, :method)
          self.sort = options
        else
          self.sort = true
        end
      else
        self.sort = false
      end
    end

    # associate an action_link with this column
    attr_reader :link

    def set_link(action, options = {})
      if action.is_a? ActiveScaffold::DataStructures::ActionLink
        @link = action
      else
        options[:label] ||= @label
        options[:position] ||= :after
        options[:type] ||= :record
        @link = ActiveScaffold::DataStructures::ActionLink.new(action, options)
      end
    end

    # set whether to calculate totals for this column
    attr_writer :calculate_total

    # get whether to calculate totals for this column
    def calculate_total?
      @calculate_total
    end

    # a collection of associations to pre-load when finding the records on a page
    attr_accessor :includes

    # describes how to search on a column
    #   search = true           default, uses intelligent search sql
    #   search = "CONCAT(a, b)" define your own sql for searching. this should be the "left-side" of a WHERE condition. the operator and value will be supplied by ActiveScaffold.
    attr_writer :search_sql
    def search_sql
      self.initialize_search_sql if @search_sql === true
      @search_sql
    end
    def searchable?
      search_sql != false && search_sql != nil
    end

    # ----------------------------------------------------------------- #
    # the below functionality is intended for internal consumption only #
    # ----------------------------------------------------------------- #

    # checks whether this column is authorized for the given user (and possibly the given action)
    def authorized?(current_user, action = nil)
      security_method = "#{@name}_authorized_for_#{action}?" if action
      security_method = "#{@name}_authorized?" unless security_method and @active_record_class.respond_to?(security_method)
      return true unless @active_record_class.respond_to? security_method
      return @active_record_class.send(security_method, current_user)
    end

    # the ConnectionAdapter::*Column object from the ActiveRecord class
    attr_reader :column

    # the association from the ActiveRecord class
    attr_reader :association

    # an interpreted property. the column is virtual if it isn't from the active record model or any associated models
    def virtual?
      @column.nil? && association.nil?
    end

    # this is so that array.delete and array.include?, etc., will work by column name
    def ==(other) #:nodoc:
      # another column
      if other.respond_to? :name and other.class == self.class
        self.name == other.name.to_sym
      # a string or symbol
      elsif other.respond_to? :to_sym
        self.name == other.to_sym rescue false # catch "interning empty string"
      # unknown
      else
        self.eql? other
      end
    end

    # instantiation is handled internally through the DataStructures::Columns object
    def initialize(name, active_record_class) #:nodoc:
      self.name = name.to_sym
      @column = active_record_class.columns_hash[self.name.to_s]
      @association = active_record_class.reflect_on_association(self.name)
      @active_record_class = active_record_class
      @table = active_record_class.table_name

      # default all the configurable variables
      self.label = self.name.to_s.titleize
      self.css_class = ''
      self.required = false
      self.calculate_total = false
      self.sort = true
      self.search_sql = true

      self.includes = association ? [association.name] : []
    end

    # just the field (not table.field)
    def field_name
      return nil if virtual?
      @column ? @column.name : @association.primary_key_name
    end

    protected

    def initialize_sort
      if self.virtual?
        # we don't automatically enable method sorting for virtual columns because it's slow, and we expect fewer complaints this way.
        self.sort = false
      else
        if association.nil?
          self.sort = {:sql => self.field}
        else
          case association.macro
            when :has_one, :belongs_to
            self.sort = {:method => "#{self.name}.to_s"}

            when :has_many, :has_and_belongs_to_many
            self.sort = {:method => "#{self.name}.join(',')"}
          end
        end
      end
    end

    def initialize_search_sql
      if self.virtual?
        self.search_sql = nil
      else
        if association.nil?
          self.search_sql = self.field.to_s.downcase
        else
          # with associations we really don't know what to sort by without developer intervention. we could sort on the primary key ('id'), but that's hardly useful. previously ActiveScaffold would try and search using the same sql as from :sort, but we decided to just punt.
          self.search_sql = nil
        end
      end
    end

    # the table name from the ActiveRecord class
    attr_reader :table

    # the table.field name for this column, if applicable
    def field
      @field ||= [@table, field_name].join('.')
    end
  end
end
