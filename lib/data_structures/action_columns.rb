module ActiveScaffold::DataStructures
  # A set of columns. These structures can be nested for organization.
  class ActionColumns
    include ActiveScaffold::Configurable
    attr_accessor :label

    def initialize(*args)
      @set = []
      self.add *args
    end

    # the way to remove columns from the set.
    def exclude(*args)
      args.collect! { |a| a.to_sym } # symbolize the args
      @set.reject! { |c| args.include? c.to_sym } # reject all columns specified
    end

    # the way to add columns to the set.
    def add(*args)
      args.each do |arg|
        arg = arg.to_sym unless arg.is_a? ActiveScaffold::DataStructures::ActionColumns
        @set << arg
      end
    end
    alias_method :<<, :add

    # nests a subgroup in the column set
    def add_subgroup(label, &proc)
      columns = ActiveScaffold::DataStructures::ActionColumns.new
      columns.configure &proc
      columns.label = label
      self.add columns
    end

    # returns the number of columns in the set
    def length
      @set.length
    end

    def include?(column)
      @set.each do |c|
        return true if c.is_a? ActiveScaffold::DataStructures::ActionColumns and c.include? column
        return true if c == column.to_sym
      end
      return false
    end
  end
end