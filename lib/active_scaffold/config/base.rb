module ActiveScaffold::Config
  class Base
    include ActiveScaffold::Configurable
    extend ActiveScaffold::Configurable

    def initialize(core_config)
      @core = core_config
      @action_group = self.class.action_group.clone if self.class.action_group

      # start with the ActionLink defined globally
      @link = self.class.link.clone if self.class.respond_to?(:link) && self.class.link
    end
    attr_reader :core

    def self.inherited(subclass)
      class << subclass
        # the crud type of the action. possible values are :create, :read, :update, :delete, and nil.
        # this is not a setting for the developer. it's self-description for the actions.
        def crud_type; @crud_type; end

        protected

        def crud_type=(val)
          raise ArgumentError, "unknown CRUD type #{val}" unless [:create, :read, :update, :delete].include?(val.to_sym)
          @crud_type = val.to_sym
        end
      end
    end

    # delegate
    def crud_type; self.class.crud_type end

    def label(model = nil)
      model ||= @core.label(:count => 1)
      @label.nil? ? model : as_(@label, :model => model)
    end
    
    # the user property gets set to the instantiation of the local UserSettings class during the automatic instantiation of this class.
    attr_accessor :user

    # define a default action_group for this action
    # e.g. 'members.crud'
    class_attribute :action_group

    # action_group this action should belong to
    attr_accessor :action_group

    class UserSettings
      def initialize(conf, storage, params, action = :base)
        # the session hash relevant to this action
        @session = storage
        # all the request params
        @params = params
        # the configuration object for this action
        @conf = conf
        @action = action
      end

      def [](key)
        @session[@action][key] if @action && @session[@action]
      end

      def []=(key, value)
        @session[@action] ||= {}
        if value
          @session[@action][key] = value
        else
          @session[@action].delete key
          @session.delete @action if @session[@action].empty?
        end
      end
    end
    
    def formats
      @formats ||= []
    end
    
    def formats=(val)
      @formats=val
    end
    
    private
    
    def columns=(val)
      @columns.set_values(*val) if @columns
      @columns ||= ActiveScaffold::DataStructures::ActionColumns.new(*val).tap do |columns|
        columns.action = self
        columns.set_columns(@core.columns) if @columns.respond_to?(:set_columns)
        columns
      end
      @columns
    end
  end
end
