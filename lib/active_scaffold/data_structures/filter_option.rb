module ActiveScaffold::DataStructures
  class FilterOption
    attr_reader :name
    attr_writer :label, :description
    attr_accessor :security_method, :conditions, :parameters

    def initialize(name, options = {})
      @label = @name = name.to_sym
      options.each do |key, value|
        setter = "#{key}="
        send(setter, value) if respond_to? setter
      end
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
