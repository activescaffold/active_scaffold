module ActiveScaffold::DataStructures
  class Columns
    include Enumerable
    include ActiveScaffold::Configurable

    # This accessor is used by ActionColumns to create new Column objects without adding them to this set
    attr_reader :active_record_class

    def initialize(active_record_class, *args)
      @active_record_class = active_record_class

      @set = []
      self.add *args
    end

    # the way to add columns to the set. this is primarily useful for virtual columns.
    def add(*args)
      args.flatten! # allow [] as a param
      args.each { |arg|
        arg = ActiveScaffold::DataStructures::Column.new(arg.to_sym, @active_record_class)
        @set << arg
      }
    end
    alias_method :<<, :add

    # returns an array of columns with the provided names
    def find_by_names(*names)
      @set.find_all { |column| names.include? column.name }
    end

    # returns the column of the given name.
    def find_by_name(name)
      # this works because of `def column.=='
      column = @set.find { |c| c == name }
      column
    end
    alias_method :[], :find_by_name

    def each
      @set.each {|i| yield i }
    end
  end
end