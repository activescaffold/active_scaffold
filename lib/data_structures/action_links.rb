module ActiveScaffold::DataStructures
  class ActionLinks
    include Enumerable

    def initialize
      @set = []
    end

    # adds an ActionLink, creating one from the arguments if need be
    def add(action, options = {})
      if action.is_a? ActiveScaffold::DataStructures::ActionLink
        @set << action
      else
        @set << ActiveScaffold::DataStructures::ActionLink.new(action, options)
      end
    end
    alias_method :<<, :add

    # finds an ActionLink by matching the action
    def [](val)
      @set.find {|item| item.action == val}
    end

    # iterates over the links, possibly by type
    def each(type = nil)
      type = type.to_sym if type
      @set.each {|item|
        next if type and item.type != type
        yield item
      }
    end

    def empty?
      @set.size == 0
    end

    protected

    # called during clone or dup. makes the clone/dup deeper.
    def initialize_copy(from)
      @set = []
      from.instance_variable_get('@set').each { |link| @set << link.clone }
    end
  end
end