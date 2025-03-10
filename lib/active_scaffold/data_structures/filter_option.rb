module ActiveScaffold::DataStructures
  class FilterOption
    attr_reader :name, :filter_name
    attr_writer :label, :description
    attr_accessor :security_method, :conditions, :parameters, :weight, :image

    def initialize(filter_name, name, options = {})
      @filter_name = filter_name
      @label = @name = name.to_sym
      options.each do |key, value|
        setter = "#{key}="
        send(setter, value) if respond_to? setter
      end
      @weight ||= 0
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

    def controller = nil
    def action = :index
    def column = nil
    def type = :collection
    def dynamic_parameters = nil
    def nested_link? = nil
    def confirm? = false
    def inline? = true
    def popup? = false
    def method = :get
    def refresh_on_close = false
    def keep_open? = false
    def position = false
    def toggle = false
    def dhtml_confirm? = false

    def name_to_cache
      [
        'self', type, action, "#{@filter_name}=#{@name}",
        *parameters&.map { |k, v| "#{k}=#{v.is_a?(Array) ? v.join(',') : v}" }
      ].compact.join('_').tap do |name_to_cache|
        @name_to_cache = name_to_cache unless frozen?
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
