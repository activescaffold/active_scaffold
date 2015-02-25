module ActiveScaffold::DataStructures
  class ActionLinks
    include Enumerable
    attr_accessor :default_type

    def initialize
      @set = []
      @name = :root
      @weight = 0
    end

    # adds an ActionLink, creating one from the arguments if need be
    def add(action, options = {})
      link =
        if action.is_a?(ActiveScaffold::DataStructures::ActionLink) || action.is_a?(ActiveScaffold::DataStructures::ActionLinks)
          action
        else
          options[:type] ||= default_type if default_type
          ActiveScaffold::DataStructures::ActionLink.new(action, options)
        end
      # NOTE: this duplicate check should be done by defining the comparison operator for an Action data structure
      existing = find_duplicate(link)

      if existing
        existing
      else
        # That s for backwards compatibility if we are in root of action_links
        # we have to move actionlink into members or collection subgroup
        group = (name == :root ? subgroup(link.type, link.type) : self)
        group.add_to_set(link)
        link
      end
    end
    alias_method :<<, :add

    def add_to_set(link)
      @set << link
    end

    # adds a link to a specific group
    # groups are represented as a string separated by a dot
    # eg member.crud
    def add_to_group(link, group_name = nil)
      add_to = root
      add_to = group_name.split('.').inject(root) { |group, name| group.send(name) } if group_name
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
          links << item if item.action.to_s == val.to_s
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
          links << item if item.action == link.action && item.static_controller? && item.controller == link.controller && item.parameters == link.parameters
        end
      end
      links.first
    end

    def delete(val)
      each(:include_set => true) do |link, set|
        if link.action.to_s == val.to_s
          set.delete link
          break
        end
      end
    end

    def delete_group(name)
      @set.each do |group|
        if group.name == name
          @set.delete group
          break
        else
          group.delete_group(name)
          break
        end if group.is_a?(ActiveScaffold::DataStructures::ActionLinks)
      end
    end

    # iterates over the links, possibly by type
    def each(options = {}, &block)
      method = options[:reverse] ? :reverse_each : :each
      @set.sort_by(&:weight).send(method) do |item|
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
      subgroup(type).each(type) { |link| links << link }
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
        group.default_type = self.name == :root ? (name.to_sym if %w(member collection).include?(name.to_s)) : default_type
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
        def #{name}(label = nil)
          @#{name} ||= subgroup('#{name}'.to_sym, label)
          yield @#{name} if block_given?
          @#{name}
        end
      }
      send(name, args.first, &block)
    end

    attr_accessor :name
    attr_accessor :weight

    protected

    # called during clone or dup. makes the clone/dup deeper.
    def initialize_copy(from)
      @set = []
      from.instance_variable_get('@set').each { |link| @set << link.clone }
    end
  end
end
