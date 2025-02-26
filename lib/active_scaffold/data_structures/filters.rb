module ActiveScaffold::DataStructures
  class Filters
    def initialize
      @set = []
      @default_type = self.class.default_type
    end

    # adds a FilterOption, creating one from the arguments if need be
    def add(name, &block)
      if name.is_a?(ActiveScaffold::DataStructures::Filter)
        filter = name
        name = filter.name
      end
      existing = self[name]
      return existing if existing

      filter ||= ActiveScaffold::DataStructures::Filter.new(name, default_type)
      @set << filter
      block.call filter
      self
    end
    alias << add

    # finds a FilterOption by matching the name
    def [](name)
      @set.find { |filter| filter.name.to_s == name.to_s }
    end

    def delete(name)
      @set.delete self[name]
    end

    # iterates over the links, possibly by type
    def each(&block)
      @set.each(&block)
    end

    def empty?
      @set.empty?
    end

    # default filter type for all app filters, can be :links or :select
    cattr_accessor :default_type

    # default filter type for all filters in this set, can be :links or :select
    attr_accessor :default_type
  end
end
