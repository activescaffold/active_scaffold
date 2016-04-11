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

    def name
      @label.to_s.underscore
    end

    def css_class
      @label.to_s.underscore.gsub /[^-_0-9a-zA-Z]/, '-'
    end

    # this is so that array.delete and array.include?, etc., will work by column name
    def ==(other) #:nodoc:
      # another ActionColumns
      if other.class == self.class
        label == other.label
      else
        @label.to_s == other.to_s
      end
    end

    # Whether this column set is collapsed by default in contexts where collapsing is supported
    attr_accessor :collapsed

    # nests a subgroup in the column set
    def add_subgroup(label, &proc)
      columns = ActiveScaffold::DataStructures::ActionColumns.new
      columns.label = label
      columns.action = action
      columns.configure(&proc)
      exclude columns.collect_columns
      add columns
    end

    def include?(item)
      @set.each do |c|
        return true if !c.is_a?(Symbol) && c.include?(item)
        return true if c == item.to_sym
      end
      false
    end

    def names
      if @columns
        collect_visible(:flatten => true) { |c| c.name }
      else
        names_without_auth_check
      end
    end

    def names_without_auth_check
      Array(@set)
    end

    # Redefine the each method to yield actual Column objects.
    # It will skip constrained and unauthorized columns.
    #
    # Options:
    #  * :flatten - whether to recursively iterate on nested sets. default is false.
    #  * :for - the record (or class) being iterated over. used for column-level security. default is the class.
    def each(options = {}, &proc)
      options[:for] ||= @columns.active_record_class unless @columns.nil?
      self.unauthorized_columns = []
      @set.each do |item|
        unless item.is_a?(ActiveScaffold::DataStructures::ActionColumns) || @columns.nil?
          item = (@columns[item] || ActiveScaffold::DataStructures::Column.new(item.to_sym, @columns.active_record_class))
          next if self.skip_column?(item, options)
        end
        if item.is_a? ActiveScaffold::DataStructures::ActionColumns
          if options[:flatten]
            item.each(options, &proc)
          elsif !options[:skip_groups]
            yield item
          end
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
        unless item.is_a?(ActiveScaffold::DataStructures::ActionColumns) || @columns.nil?
          item = (@columns[item] || ActiveScaffold::DataStructures::Column.new(item.to_sym, @columns.active_record_class))
          next if self.skip_column?(item, options)
        end
        if item.is_a?(ActiveScaffold::DataStructures::ActionColumns) && options.key?(:flatten) && options[:flatten]
          columns += item.collect_visible(options, &proc)
        else
          columns << (block_given? ? yield(item) : item)
        end
      end
      columns
    end

    def skip_column?(column, options)
      # skip if this matches a constrained column
      return true if constraint_columns.include?(column.name.to_sym)
      # skip this field if it's not authorized
      unless options[:for].authorized_for?(:action => options[:action], :crud_type => options[:crud_type] || action.try(:crud_type) || :read, :column => column.name)
        unauthorized_columns << column.name.to_sym
        return true
      end
      false
    end

    # registers a set of column objects (recursively, for all nested ActionColumns)
    def set_columns(columns)
      @columns = columns
      # iterate over @set instead of self to avoid dealing with security queries
      @set.each do |item|
        item.set_columns(columns) if item.respond_to? :set_columns
      end
    end

    def action_name
      @action.class.name.demodulize.underscore
    end

    def constraint_columns_key
      "#{@action.core.model_id.to_s.underscore}-#{action_name}"
    end

    def constraint_columns=(columns)
      Thread.current[:constraint_columns] ||= {}
      Thread.current[:constraint_columns][constraint_columns_key] = columns
    end

    def constraint_columns
      constraints = Thread.current[:constraint_columns]
      (constraints[constraint_columns_key] if constraints) || []
    end

    attr_writer :unauthorized_columns
    def unauthorized_columns
      @unauthorized_columns ||= []
    end

    def length
      ((@set - constraint_columns) - unauthorized_columns).length
    end

    protected

    def collect_columns
      @set.collect { |col| col.is_a?(ActiveScaffold::DataStructures::ActionColumns) ? col.collect_columns : col }
    end

    # called during clone or dup. makes the clone/dup deeper.
    def initialize_copy(from)
      @set = from.instance_variable_get('@set').clone
    end
  end
end
