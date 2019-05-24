module ActiveScaffold
  module DelayedSetup
    def self.included(base)
      base.extend ClassMethods
    end

    def process(*)
      self.class.config_active_scaffold_delayed
      super
    end

    module ClassMethods
      def active_scaffold(model_id = nil, &block)
        @delayed_mutex ||= Mutex.new
        @active_scaffold_delayed = proc { super(model_id, &block) }
      end

      def config_active_scaffold_delayed
        return if @delayed_mutex.nil? || Thread.current["#{name}_running_delayed_init"]
        @delayed_mutex.synchronize do
          return unless @active_scaffold_delayed
          @_prefixes = nil # clean prefixes in case is already cached, so our local_prefixes override is picked up
          Thread.current["#{name}_running_delayed_init"] = true
          block = @active_scaffold_delayed
          @active_scaffold_delayed = nil # clear before called, active_scaffold_config may be called inside block
          block.call
          Thread.current["#{name}_running_delayed_init"] = nil
        end
        @delayed_mutex = nil
      end

      def active_scaffold_config
        config_active_scaffold_delayed
        super
      end
    end
  end
end
