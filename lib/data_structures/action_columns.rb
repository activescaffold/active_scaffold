module ActiveScaffold::DataStructures
  # A set of columns. These structures can be nested for organization.
  class ActionColumns < Set
    include ActiveScaffold::Configurable
    attr_accessor :label

    # nests a subgroup in the column set
    def add_subgroup(label, &proc)
      columns = ActiveScaffold::DataStructures::ActionColumns.new
      columns.configure &proc
      columns.label = label
      self.add columns
    end

    def each # this comes later
    end
    
    def include?(item)
      @set.each do |c|
        return true if !c.is_a? Symbol and c.include? item
        return true if c == item.to_sym
      end
      return false
    end

  end
end