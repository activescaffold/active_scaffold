module ActiveScaffold::DataStructures
  class ActionLinks
    include Enumerable

    def initialize
      @set = []
    end

    # adds an ActionLink, creating one from the arguments if need be
    def add(action, options = {})
      link = if action.is_a?(ActiveScaffold::DataStructures::ActionLink) || action.is_a?(ActiveScaffold::DataStructures::ActionLinks)
        action
      else
        ActiveScaffold::DataStructures::ActionLink.new(action, options)
      end
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
      @set.each {|item|
        yield item
      }
    end
    
    def collect_by_type(type = nil)
      links = []
      subgroup(type).each(type) {|link| links << link}
      links
    end

    def traverse(controller, options = {}, &block)
      @set.each do |link|
        if link.is_a?(ActiveScaffold::DataStructures::ActionLinks)
          # add top node only if there is anything in the list
          #yield({:kind => :node, :level => 1, :last => false, :link => link})
          yield(link, nil, {:node => :start_traversing})
          link.traverse(options, &block)
          yield(link, nil, {:node => :finished_traversing})
          #yield({:kind => :completed_group, :level => 1, :last => false, :link => link})
        elsif controller.nil? || !skip_action_link(controller, link, options)
          authorized = options[:for].nil? ? true : options[:for].authorized_for?(:crud_type => link.crud_type, :action => link.action)
          yield(self, link, {:authorized => authorized})
        end
      end
    end

    def collect
      @set.collect
    end

    def empty?
      @set.size == 0
    end

    def subgroup(name, label = nil)
      group = self if name == self.name
      group ||= @set.find do |item|
        name == item.name if item.is_a?(ActiveScaffold::DataStructures::ActionLinks)
      end

      if group.nil?
        group = ActiveScaffold::DataStructures::ActionLinks.new
        group.label = label || name
        group.name = name
        add_to_set group
      end
      group
    end

    attr_writer :label
    def label
      as_(@label) if @label
    end

    def method_missing(name, *args, &block)
      class_eval %{
        def #{name}
          @#{name} ||= subgroup('#{name}'.to_sym)
          yield @#{name} if block_given?
          @#{name}
        end
      }
      send(name, &block)
    end

    attr_accessor :name

    protected

    def skip_action_link(controller, link, *args)
      (!link.ignore_method.nil? and controller.try(link.ignore_method, *args)) || ((link.security_method_set? or controller.respond_to? link.security_method) and !controller.send(link.security_method, *args))
    end

    # called during clone or dup. makes the clone/dup deeper.
    def initialize_copy(from)
      @set = []
      from.instance_variable_get('@set').each { |link| @set << link.clone }
    end
  end
end