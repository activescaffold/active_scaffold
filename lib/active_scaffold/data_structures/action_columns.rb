module ActiveScaffold::DataStructures
  # A set of columns. These structures can be nested for organization.
  class ActionColumns < ActiveScaffold::DataStructures::Set
    include ActiveScaffold::Configurable

    # this lets us refer back to the action responsible for this link, if it exists.
    # the immediate need here is to get the crud_type so we can dynamically filter columns from the set.
    attr_accessor :action

    # labels are useful for the Create/Update forms, when we display columns in a grouped fashion and want to name them separately
    attr_writer :label
    def label
      as_(@label) if @label
    end

    # Whether this column set is collapsed by default in contexts where collapsing is supported
    attr_accessor :collapsed
    
    # nests a subgroup in the column set
    def add_subgroup(label, &proc)
      columns = ActiveScaffold::DataStructures::ActionColumns.new
      columns.label = label
      columns.action = self.action
      columns.configure &proc
      self.exclude columns.collect_columns
      self.add columns
    end

    def include?(item)
      @set.each do |c|
        return true if !c.is_a? Symbol and c.include? item
        return true if c == item.to_sym
      end
      return false
    end

    def names
      self.collect(&:name)
    end

    def names_without_auth_check
      Array(@set)
    end

    protected

    def collect_columns
      @set.collect {|col| col.is_a?(ActiveScaffold::DataStructures::ActionColumns) ? col.collect_columns : col}
    end

    # called during clone or dup. makes the clone/dup deeper.
    def initialize_copy(from)
      @set = from.instance_variable_get('@set').clone
    end

    # A package of stuff to add after the configuration block. This is an attempt at making a certain level of functionality inaccessible during configuration, to reduce possible breakage from misuse.
    # The bulk of the package is a means of connecting the referential column set (ActionColumns) with the actual column objects (Columns). This lets us iterate over the set and yield real column objects.
    module AfterConfiguration
      # Redefine the each method to yield actual Column objects.
      # It will skip constrained and unauthorized columns.
      #
      # Options:
      #  * :flatten - whether to recursively iterate on nested sets. default is false.
      #  * :for - the record (or class) being iterated over. used for column-level security. default is the class.
      def each(options = {}, &proc)
        options[:for] ||= @columns.active_record_class
        self.unauthorized_columns = []
        @set.each do |item|
          unless item.is_a? ActiveScaffold::DataStructures::ActionColumns
            item = (@columns[item] || ActiveScaffold::DataStructures::Column.new(item.to_sym, @columns.active_record_class))
            next if self.skip_column?(item, options)
          end
          if item.is_a? ActiveScaffold::DataStructures::ActionColumns and options.has_key?(:flatten) and options[:flatten]
            item.each(options, &proc)
          else
            yield item
          end
        end
      end
      
      def collect_visible(options = {}, &proc)
        columns = []
        options[:for] ||= @columns.active_record_class
        self.unauthorized_columns = []
        @set.each do |item|
          unless item.is_a? ActiveScaffold::DataStructures::ActionColumns
            item = (@columns[item] || ActiveScaffold::DataStructures::Column.new(item.to_sym, @columns.active_record_class))
            next if self.skip_column?(item, options)
          end
          if item.is_a? ActiveScaffold::DataStructures::ActionColumns and options.has_key?(:flatten) and options[:flatten]
            columns = columns + item.collect(options, &proc)
          else
            columns << item
          end
        end
        columns
      end      
      
      def skip_column?(column, options)
        result = false
        # skip if this matches a constrained column
        result = true if constraint_columns.include?(column.name.to_sym)
        # skip if this matches the field_name of a constrained column
        result = true if column.field_name and constraint_columns.include?(column.field_name.to_sym)
        # skip this field if it's not authorized
        unless options[:for].authorized_for?(:action => options[:action], :crud_type => options[:crud_type] || self.action.crud_type, :column => column.name)
          self.unauthorized_columns << column.name.to_sym
          result = true
        end
        return result
      end

      # registers a set of column objects (recursively, for all nested ActionColumns)
      def set_columns(columns)
        @columns = columns
        # iterate over @set instead of self to avoid dealing with security queries
        @set.each do |item|
          item.set_columns(columns) if item.respond_to? :set_columns
        end
      end

      attr_writer :constraint_columns
      def constraint_columns
        @constraint_columns ||= []
      end
      
      attr_writer :unauthorized_columns
      def unauthorized_columns
        @unauthorized_columns ||= []
      end
      
      def length
        ((@set - self.constraint_columns) - self.unauthorized_columns).length
      end
    end
  end
end
