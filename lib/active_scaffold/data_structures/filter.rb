# frozen_string_literal: true

module ActiveScaffold::DataStructures
  class Filter
    include Enumerable

    attr_reader :name, :default_option
    attr_writer :label, :description
    attr_accessor :type, :weight, :css_class, :security_method

    def initialize(name, type)
      raise ArgumentError, 'Filter name must use only word characters (a-zA-Z0-9_)' unless name.match?(/\A\w+\z/)

      @label = @name = name.to_sym
      @type = type
      @options = []
      @weight = 0
    end

    # adds a FilterOption, creating one from the arguments if need be
    def add(name, options = {})
      if name.is_a?(ActiveScaffold::DataStructures::FilterOption)
        option = name
        name = option.name
      end
      existing = self[name]
      raise ArgumentError, "there is a filter option with '#{name}' name" if existing

      option ||= ActiveScaffold::DataStructures::FilterOption.new(@name, name, options)
      @default_option ||= option.name
      @options << option
      self
    end
    alias << add

    def default_option=(name)
      option = self[name]
      raise ArgumentError, "'#{name}' option not found" unless option

      @default_option = option.name
    end

    # finds a FilterOption by matching the name
    def [](option_name)
      @options.find { |option| option.name.to_s == option_name.to_s }
    end

    def delete(option_name)
      @options.delete self[option_name]
    end

    # iterates over the links, possibly by type
    def each(&)
      @options.each(&)
    end

    def empty?
      @options.empty?
    end

    def label(*)
      case @label
      when Symbol
        ActiveScaffold::Registry.cache(:translations, @label) { as_(@label) }
      else
        @label
      end
    end

    def description
      case @description
      when Symbol
        ActiveScaffold::Registry.cache(:translations, @description) { as_(@description) }
      else
        @description
      end
    end

    protected

    # called during clone or dup. makes the clone/dup deeper.
    def initialize_copy(from)
      @options = []
      from.each { |option| @options << option.clone }
    end
  end
end
