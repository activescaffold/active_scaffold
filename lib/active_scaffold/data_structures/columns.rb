module ActiveScaffold::DataStructures
  class Columns
    include Enumerable
    include ActiveScaffold::Configurable

    # The motivation for this collection is that this Columns data structure fills two roles: it provides
    # the master list of all known columns, and it provides an inheritable list for all other actions (e.g.
    # Create and Update and List). Well we actually want to *know* about as many columns as possible, so
    # we don't want people actually removing columns from @set. But at the same time, we want to be able to
    # manage which columns get inherited. Tada!
    #
    # This collection is referenced by other parts of ActiveScaffold and by methods within this DataStructure.
    # IT IS NOT MEANT FOR PUBLIC USE (but if you know what you're doing, go ahead)
    def _inheritable=(value)
      @sorted = true
      @_inheritable = value
    end

    # This accessor is used by ActionColumns to create new Column objects without adding them to this set
    attr_reader :active_record_class

    def initialize(active_record_class, *args)
      @active_record_class = active_record_class
      @_inheritable = []
      @set = []

      add(*args)
    end

    # the way to add columns to the set. this is primarily useful for virtual columns.
    # note that this also makes columns inheritable
    def add(*args)
      args.flatten! # allow [] as a param
      args = args.collect(&:to_sym)

      # make the columns inheritable
      @_inheritable.concat(args)
      # then add columns to @set (unless they already exist)
      args.each { |a| @set << ActiveScaffold::DataStructures::Column.new(a.to_sym, @active_record_class) unless find_by_name(a) }
    end
    alias << add

    # add columns from association (belongs_to or has_one)
    # these columns will use label translation from association model
    # they will be excluded, so won't be included in action columns
    # association columns will work for read actions only, not in form actions (create, update, subform)
    def add_association_columns(association, *columns)
      column = self[association]
      if column.nil?
        raise ArgumentError, "unknown column #{association}"
      elsif column.association.nil?
        raise ArgumentError, "column #{association} is not an association"
      elsif !column.association.singular?
        raise ArugmentError, "column #{association} is not singular association"
      elsif column.association.polymorphic?
        raise ArugmentError, "column #{association} is polymorphic association"
      else
        klass = column.association.klass
        columns.each do |col|
          next if find_by_name col
          @set << ActiveScaffold::DataStructures::Column.new(col, klass, column.association)
        end
      end
    end

    def exclude(*args)
      # only remove columns from _inheritable. we never want to completely forget about a column.
      args.each { |a| @_inheritable.delete a.to_sym }
    end

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
    alias [] find_by_name

    def each
      @set.each { |i| yield i }
    end

    def _inheritable
      if @sorted
        @_inheritable
      else
        @_inheritable.sort do |a, b|
          self[a] <=> self[b]
        end
      end
    end
  end
end
