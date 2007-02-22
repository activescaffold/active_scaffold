module ActiveScaffold::DataStructures
  class Columns
    include Enumerable
    include ActiveScaffold::Configurable

    attr_reader :unauthorized_columns

    # This accessor is used by ActionColumns to create new Column objects without adding them to this set
    attr_reader :active_record_class

    def initialize(active_record_class, *args)
      @active_record_class = active_record_class

      @set = []
      @unauthorized_columns = []
      self.add *args
    end

    # the way to add columns to the set. this is primarily useful for virtual columns.
    def add(*args)
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
      raise ActiveScaffold::ColumnNotAllowed if unauthorized_columns.include? column
      column
    end
    alias_method :[], :find_by_name

    def each
      @set.each {|i| yield i unless unauthorized_columns.include? i }
    end

    # at some point we need to determine if any of the columns in this set are not authorized for the current user and action
    # this method needs to be called in a before_filter so that @unauthorized_columns is created before any action
    # the columns in @set that are not authorized for the current user/action will be blacklisted here
    def create_blacklist(current_user, action)
      @unauthorized_columns = []
      @set.each do |column|
        self.unauthorized_columns << column unless column.authorized?(current_user, action)
      end
    end
  end
end