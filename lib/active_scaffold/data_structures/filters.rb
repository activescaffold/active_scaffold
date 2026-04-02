# frozen_string_literal: true

module ActiveScaffold::DataStructures
  class Filters
    include Enumerable

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
      raise ArgumentError, "there is a filter with '#{name}' name" if existing

      filter ||= ActiveScaffold::DataStructures::Filter.new(name, default_type)
      @set << filter
      block&.call filter
      self
    end
    alias << add

    # finds a Filter by matching the name
    def [](name)
      @set.find { |filter| filter.name.to_s == name.to_s }
    end

    def delete(name)
      @set.delete self[name]
    end

    # iterates over the links, possibly by type
    def each(&)
      @set.each(&)
    end

    delegate :empty?, to: :@set

    # default filter type for all app filters, can be :links or :select
    cattr_accessor :default_type
    @@default_type = :links

    # default filter type for all filters in this set, can be :links or :select
    attr_accessor :default_type
  end
end
