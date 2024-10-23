module ActiveScaffold::DataStructures
  class ActionLinks
    include Enumerable
    attr_accessor :default_type

    def initialize(name = :root)
      @set = []
      @name = name
      @css_class = name.to_s.downcase
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
    alias << add

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
        elsif item.action.to_s == val.to_s
          links << item
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
        elsif item.action == link.action && item.static_controller? && item.controller == link.controller && item.parameters == link.parameters
          links << item
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

    def collect_by_type(type = nil)
      links = []
      subgroup(type).each(type) { |link| links << link }
      links
    end

    def collect
      @set
    end

    def empty?
      @set.empty?
    end

    def subgroup(name, label = nil)
      group = self if name == self.name
      group ||= @set.find do |item|
        name == item.name if item.is_a?(ActiveScaffold::DataStructures::ActionLinks)
      end

      if group.nil?
        raise RuntimeError, "Can't add new subgroup '#{name}', links are frozen" if frozen?
        group = ActiveScaffold::DataStructures::ActionLinks.new(name)
        group.label = label || name
        group.default_type = self.name == :root ? (name.to_sym if %w[member collection].include?(name.to_s)) : default_type
        add_to_set group
      end
      group
    end

    attr_writer :label
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

    def method_missing(name, *args, &block)
      return super if name.match?(/[!?]$/)
      return subgroup(name.to_sym, args.first, &block) if frozen?
      class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{name}(label = nil) # rubocop:disable Style/CommentedKeyword
          @#{name} ||= subgroup('#{name}'.to_sym, label)
          yield @#{name} if block_given?
          @#{name}
        end
      METHOD
      send(name, args.first, &block)
    end

    def respond_to_missing?(name, *)
      name !~ /[!?]$/
    end

    attr_reader :name
    attr_accessor :weight
    attr_accessor :css_class

    def name=(value)
      ActiveSupport::Deprecation.warn "Changing name is deprecated, use css_class to change the class html attribute"
      self.css_class = value
    end

    protected

    # called during clone or dup. makes the clone/dup deeper.
    def initialize_copy(from)
      @set = []
      from.instance_variable_get('@set').each { |link| @set << link.clone }
    end
  end
end
