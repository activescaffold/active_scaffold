# frozen_string_literal: true

module ActiveScaffold::Config
  class Base
    include ActiveScaffold::Configurable
    extend ActiveScaffold::Configurable
    NO_FORMATS = [].freeze

    def initialize(core_config)
      @core = core_config
      @action_group = self.class.action_group.clone if self.class.action_group

      # start with the ActionLink defined globally
      @link = self.class.link.clone if self.class.respond_to?(:link) && self.class.link
      setup_user_setting_key
    end

    def setup_user_setting_key
      @user_settings_key = :"#{model_id}_#{self.class.name.underscore}"
    end

    attr_reader :core, :user_settings_key

    # delegate
    def crud_type
      self.class.crud_type
    end

    def label(model = nil)
      model ||= @core.label(count: 1)
      @label.nil? ? model : as_(@label, model: model)
    end

    def model_id
      (core || self).model_id
    end

    # the user property gets set to the instantiation of the local UserSettings class during the automatic instantiation of this class.
    def user
      ActiveScaffold::Registry.user_settings[user_settings_key]
    end

    def new_user_settings(storage, params)
      ActiveScaffold::Registry.user_settings[user_settings_key] = self.class::UserSettings.new(self, storage, params)
    end

    # define a default action_group for this action
    # e.g. 'members.crud'
    class_attribute :action_group, instance_accessor: false

    # action_group this action should belong to
    attr_accessor :action_group

    def formats
      return @formats || NO_FORMATS if frozen?

      @formats ||= NO_FORMATS.dup
    end
    attr_writer :formats

    class UserSettings
      # define setter and getter for names
      # values will be saved for current request only
      # getter will return value set with setter, or value from conf
      def self.user_attr(*names)
        attr_writer(*names)

        names.each do |name|
          define_method(name) do
            instance_variable_defined?(:"@#{name}") ? instance_variable_get(:"@#{name}") : @conf.send(name)
          end
        end
      end

      # define setter and getter for names
      # values will be saved in session if store_user_settings is enabled,
      # in other case for current request only
      # getter will return value set with setter, or value from conf
      def self.session_attr(*names)
        names.each do |name|
          define_method(name) { |value| self[name] = value }
          define_method(name) { key?(name) ? self[name] : @conf.send(name) }
        end
      end

      def initialize(conf, storage, params, action = :base)
        # the session hash relevant to this action
        @storage = storage
        # all the request params
        @params = params
        # the configuration object for this action
        @conf = conf
        @action = action.to_s
      end

      def user
        self
      end

      def core
        @conf.core.user
      end

      def [](key)
        @storage[@action][key.to_s] if @action && @storage[@action]
      end

      def []=(key, value)
        @storage[@action] ||= {}
        if value.present?
          @storage[@action][key.to_s] = value
        else
          @storage[@action].delete key.to_s
          @storage.delete @action if @storage[@action].empty?
        end
      end

      def key?(key)
        @storage[@action].key? key.to_s if @action && @storage[@action]
      end

      def method_missing(name, *args)
        proxy_to_conf?(name, true) ? @conf.send(name, *args) : super
      end

      def respond_to_missing?(name, include_all = false)
        proxy_to_conf?(name, include_all) || super
      end

      def proxy_to_conf?(name, include_all)
        name !~ /=$/ && @conf.respond_to?(name, include_all)
      end
    end

    def self.inherited(subclass)
      super
      subclass.const_set :UserSettings, Class.new(subclass.superclass::UserSettings)
      class << subclass
        # the crud type of the action. possible values are :create, :read, :update, :delete, and nil.
        # this is not a setting for the developer. it's self-description for the actions.
        attr_reader :crud_type

        protected

        def crud_type=(val)
          raise ArgumentError, "unknown CRUD type #{val}" unless %i[create read update delete].include?(val.to_sym)

          @crud_type = val.to_sym
        end
      end
    end

    private

    def build_action_columns(val)
      @core.build_action_columns self, val
    end

    class_attribute :columns_collections

    def self.columns_writer(name)
      var = :"@#{name}"
      define_method :"#{name}=" do |val|
        if instance_variable_defined?(var)
          instance_variable_get(var).set_values(*val)
          instance_variable_get(var)
        else
          instance_variable_set(var, build_action_columns(val))
        end
      end
    end

    def self.columns_reader(name, options, &block)
      var = :"@#{name}"
      define_method name do
        unless instance_variable_defined?(var) # lazy evaluation
          action, columns = options[:copy] if options[:copy]
          if action && @core.actions.include?(action)
            action_columns = @core.send(action).send(columns || :columns).clone
            action_columns.action = self
            instance_variable_set(var, action_columns)
          else
            send(:"#{name}=", @core.columns._inheritable)
          end
          instance_exec(&block) if block
        end
        instance_variable_get(var)
      end
    end

    def self.columns_accessor(*names, &block)
      options = names.extract_options!
      self.columns_collections = ((columns_collections || []) + names).uniq
      names.each do |name|
        columns_writer name
        columns_reader name, options, &block unless method_defined? name

        var = :"@#{name}"
        self::UserSettings.class_eval do
          define_method :"#{name}=" do |val|
            instance_variable_set var, build_action_columns(val)
          end
          define_method name do
            instance_variable_get(var) || @conf.send(name)
          end
          define_method :"override_#{name}" do |&blck|
            send(:"#{name}=", send(name)).tap { |cols| blck&.call cols }
          end
        end
      end
    end

    private_class_method :columns_accessor, :columns_reader, :columns_writer
  end
end
