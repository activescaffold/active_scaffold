# frozen_string_literal: true

module ActiveScaffold::DataStructures
  class ActionLinks
    include Enumerable

    COLLECTION_CLICK_MENU_LINK = ActionLink.new(:index, position: false, type: :member, toggle: false, parameters: {action_links: '--ACTION-LINKS--', id: nil}) # member so it's cached
    MEMBER_CLICK_MENU_LINK = ActionLink.new(:index, position: false, type: :member, toggle: false, parameters: {action_links: '--ACTION-LINKS--'})

    attr_accessor :default_type, :weight, :css_class
    attr_writer :click_menu, :label
    attr_reader :name, :path

    def initialize(name = :root, parent_path = nil)
      @set = []
      @name = name
      @css_class = name.to_s.downcase
      @weight = 0
      @path = [parent_path, name].compact.join('.') unless name == :root
    end

    def click_menu?
      @click_menu
    end

    alias name_to_cache path

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
    alias << add

    def add_separator(weight = 0)
      raise 'Call add_separator on a group' if name == :root

      add_to_set ActionLinkSeparator.new(weight)
    end

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
        next if item == :separator

        if item.is_a?(ActiveScaffold::DataStructures::ActionLinks)
          collected = item[val]
          links << collected unless collected.nil?
        elsif item.action.to_s == val.to_s
          links << item
        end
      end
      links.first
    end

    def find_duplicate(link)
      links = []
      @set.each do |item|
        next if item == :separator

        if item.is_a?(ActiveScaffold::DataStructures::ActionLinks)
          collected = item.find_duplicate(link)
          links << collected unless collected.nil?
        elsif item.action == link.action && item.static_controller? && item.controller == link.controller && item.parameters == link.parameters
          links << item
        end
      end
      links.first
    end

    def delete(val)
      each(include_set: true) do |link, set|
        next if link == :separator

        if link.action.to_s == val.to_s
          set.delete link
          break
        end
      end
    end

    def delete_group(name)
      @set.each do |group|
        next unless group.is_a?(ActiveScaffold::DataStructures::ActionLinks)

        if group.name == name
          @set.delete group
          break
        else
          group.delete_group(name)
        end
      end
    end

    # iterates over the links, possibly by type
    def each(options = {}, &block)
      method = options[:reverse] ? :reverse_each : :each
      @set.sort_by(&:weight).send(method) do |item|
        if item.is_a?(ActiveScaffold::DataStructures::ActionLinks) && !options[:groups]
          item.each(options, &block)
        elsif options[:include_set]
          yield item, @set
        else
          yield item
        end
      end
    end

    def collect
      @set
    end

    delegate :empty?, to: :@set

    def subgroup(name, label = nil)
      name = name.to_sym
      group = self if name == self.name
      group ||= @set.find do |item|
        name == item.name if item.is_a?(ActiveScaffold::DataStructures::ActionLinks)
      end

      if group.nil?
        raise FrozenError, "Can't add new subgroup '#{name}', links are frozen" if frozen?

        group = ActiveScaffold::DataStructures::ActionLinks.new(name, path)
        group.label = label || name
        group.default_type = self.name == :root ? (name if %i[member collection].include?(name)) : default_type
        add_to_set group
      end
      group
    end

    def label(record)
      case @label
      when Symbol
        ActiveScaffold::Registry.cache(:translations, @label) { as_(@label) }
      when Proc
        @label.call(record)
      else
        @label
      end
    end

    def method_missing(name, *args, &)
      return super if name.match?(/[=!?]$/)
      return subgroup(name.to_sym, args.first, &) if frozen?

      define_singleton_method name do |label = nil|
        value = instance_variable_get("@#{name}")
        unless value
          value = subgroup(name.to_sym, label)
          instance_variable_set("@#{name}", value)
        end
        yield value if block_given?
        value
      end
      send(name, args.first, &)
    end

    def respond_to_missing?(name, *)
      name !~ /[=!?]$/
    end

    protected

    # called during clone or dup. makes the clone/dup deeper.
    def initialize_copy(from)
      @set = []
      from.instance_variable_get(:@set).each { |link| @set << link.clone }
    end
  end
end
