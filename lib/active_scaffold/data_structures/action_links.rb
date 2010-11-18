module ActiveScaffold::DataStructures
  class ActionLinks
    include Enumerable

    def initialize
      @set = []
    end

    # adds an ActionLink, creating one from the arguments if need be
    def add(action, options = {})
      link = action.is_a?(ActiveScaffold::DataStructures::ActionLink) || action.is_a?(ActiveScaffold::DataStructures::ActionLinks) ? action : ActiveScaffold::DataStructures::ActionLink.new(action, options)
      # NOTE: this duplicate check should be done by defining the comparison operator for an Action data structure
      existing = find_duplicate(link)
      unless existing
        subgroup(link.type, link.type).add_to_set(link)
        link
      else
        existing
      end
    end
    alias_method :<<, :add

    def add_to_set(link)
      @set << link
    end

    # finds an ActionLink by matching the action
    def [](val)
      @set.find do |item|
        if item.is_a?(ActiveScaffold::DataStructures::ActionLinks)
          item[val]
        else
          item.action == val.to_s
        end
      end
    end

    def find_duplicate(link)
      @set.find do |item|
        if item.is_a?(ActiveScaffold::DataStructures::ActionLinks)
          item.find_duplicate(link)
        else
          item.action == link.action and item.controller == link.controller and item.parameters == link.parameters
        end
      end
    end

    def delete(val)
      @set.delete_if do |item|
        if item.is_a?(ActiveScaffold::DataStructures::ActionLinks)
          delete(val)
        else
          item.action == val.to_s
        end
      end
    end

    # iterates over the links, possibly by type
    def each(type = nil)
      type = type.to_sym if type
      @set.each {|item|
        next if type and item.type != type
        yield item
      }
    end
    
    def collect_by_type(type = nil)
      links = []
      subgroup(type).each(type) {|link| links << link}
      links
    end

    def collect
      @set.collect
    end

    def empty?
      @set.size == 0
    end

    def subgroup(name, label = nil)
      group = @set.find do |item|
        name == item.name if item.is_a?(ActiveScaffold::DataStructures::ActionLinks)
      end

      if group.nil?
        group = ActiveScaffold::DataStructures::ActionLinks.new
        group.label = label
        group.name = name
        add_to_set group
      end
      yield group if block_given?
      group
    end

    attr_writer :label
    def label
      as_(@label) if @label
    end

    def method_missing(name, *args)
      subgroup(name, name)
    end

    attr_accessor :name

    protected

    # called during clone or dup. makes the clone/dup deeper.
    def initialize_copy(from)
      @set = []
      from.instance_variable_get('@set').each { |link| @set << link.clone }
    end
  end
end