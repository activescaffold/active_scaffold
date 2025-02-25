module ActiveScaffold::DataStructures
  class Filter
    attr_reader :param
    attr_writer :label, :description
    attr_accessor :weight, :css_class

    def initialize(param)
      @label = @param = param.to_sym
      @options = []
    end

    # adds a FilterOption, creating one from the arguments if need be
    def add(name, options = {})
      if name.is_a?(ActiveScaffold::DataStructures::FilterOption)
        option = name
        name = option.name
      end
      existing = self[name]
      return existing if existing

      option ||= ActiveScaffold::DataStructures::FilterOption.new(name, options)
      @set << option
      option
    end
    alias << add

    # finds a FilterOption by matching the name
    def [](val)
      @options.find { |option| option.name.to_s == val.to_s }
    end

    def delete(val)
      @set.delete self[val]
    end

    # iterates over the links, possibly by type
    def each(&block)
      @options.each(&block)
    end

    def empty?
      @options.empty?
    end

    def label
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
