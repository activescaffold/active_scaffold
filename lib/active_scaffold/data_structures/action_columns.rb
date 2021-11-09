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
      @label.to_s.underscore.gsub(/[^-_0-9a-zA-Z]/, '-')
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

    def to_a
      Array(@set)
    end

    def skip_column?(column_name, options)
      # skip if this matches a constrained column
      return true if constraint_columns.include?(column_name.to_sym)
      # skip this field if it's not authorized
      unless options[:for].authorized_for?(action: options[:action], crud_type: options[:crud_type] || action&.crud_type || :read, column: column_name)
        unauthorized_columns << column_name.to_sym
        return true
      end
      false
    end

    def each_column(options = {}, &proc)
      columns = options[:core_columns] || action.core.columns
      self.unauthorized_columns = []
      options[:for] ||= columns.active_record_class

      each do |item|
        if item.is_a? ActiveScaffold::DataStructures::ActionColumns
          if options[:flatten]
            item.each_column(options, &proc)
          elsif !options[:skip_groups]
            yield item
          end
        else
          next if skip_column?(item, options)
          yield columns[item] || ActiveScaffold::DataStructures::Column.new(item.to_sym, columns.active_record_class)
        end
      end
    end

    def visible_columns(options = {})
      columns = []
      each_column(options) do |column|
        columns << column
      end
      columns
    end

    def visible_columns_names(options = {})
      visible_columns(options.reverse_merge(flatten: true)).map(&:name)
    end

    def action_name
      @action.user_settings_key
    end

    def columns_key
      "#{@action.core.model_id.to_s.underscore}-#{action_name}"
    end

    def constraint_columns=(columns)
      ActiveScaffold::Registry.constraint_columns[columns_key] = columns
    end

    def constraint_columns
      ActiveScaffold::Registry.constraint_columns[columns_key]
    end

    def unauthorized_columns=(columns)
      ActiveScaffold::Registry.unauthorized_columns[columns_key] = columns
    end

    def unauthorized_columns
      ActiveScaffold::Registry.unauthorized_columns[columns_key]
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
