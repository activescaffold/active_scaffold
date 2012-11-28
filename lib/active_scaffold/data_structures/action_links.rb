module ActiveScaffold::DataStructures
  class ActionLinks
    include Enumerable

    def initialize
      @set = []
      @name = :root
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
        # That s for backwards compatibility if we are in root of action_links
        # we have to move actionlink into members or collection subgroup
        group = (name == :root ? subgroup(link.type, link.type) : self)
        group.add_to_set(link)
        link
      else
        existing
      end
    end
    alias_method :<<, :add

    def add_to_set(link)
      @set << link
    end

    # adds a link to a specific group
    # groups are represented as a string separated by a dot
    # eg member.crud
    def add_to_group(link, group = nil)
      add_to = root
      add_to = group.split('.').inject(root){|group, group_name| group.send(group_name)} if group
      add_to << link unless link.nil?
    end

    # finds an ActionLink by matching the action
    def [](val)
      links = []
      @set.each do |item|
        if item.is_a?(ActiveScaffold::DataStructures::ActionLinks)
          collected = item[val]
          links << collected unless collected.nil?
        else
          links << item if item.action == val.to_s
        end
      end
      links.first
    end

    def find_duplicate(link)
      links = []
      @set.each do |item|
        if item.is_a?(ActiveScaffold::DataStructures::ActionLinks)
          collected = item.find_duplicate(link)
          links << collected unless collected.nil?
        else
          links << item if item.action == link.action and item.static_controller? && item.controller == link.controller and item.parameters == link.parameters
        end
      end
      links.first
    end

    def delete(val)
      self.each({:include_set => true}) do |link, set|
        if link.action == val.to_s
          set.delete_if {|item| item.is_a?(ActiveScaffold::DataStructures::ActionLink) && item.action == val.to_s}
        end
      end
    end

    def delete_group(name)
      @set.each do |group|
        if group.name == name
          @set.delete_if {|item| item.is_a?(ActiveScaffold::DataStructures::ActionLinks) && item.name == name}
        else
          group.delete_group(name)
        end if group.is_a?(ActiveScaffold::DataStructures::ActionLinks)
      end
    end

    # iterates over the links, possibly by type
    def each(options = {}, &block)
      method = options[:reverse] ? :reverse_each : :each
      @set.send(method) do |item|
        if item.is_a?(ActiveScaffold::DataStructures::ActionLinks) && !options[:groups]
          item.each(options, &block)
        else
          if options[:include_set]
            yield item, @set
          else
            yield item
          end
        end
      end
    end
    
    def collect_by_type(type = nil)
      links = []
      subgroup(type).each(type) {|link| links << link}
      links
    end

    def collect
      @set
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

    # called during clone or dup. makes the clone/dup deeper.
    def initialize_copy(from)
      @set = []
      from.instance_variable_get('@set').each { |link| @set << link.clone }
    end
  end
end
