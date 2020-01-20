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
        @delayed_monitor ||= Monitor.new
        @active_scaffold_delayed = proc do
          begin
            @_prefixes = nil # clean prefixes in case is already cached, so our local_prefixes override is picked up
            super(model_id, &block)
            @active_scaffold_delayed = @delayed_monitor = nil # after configuring, no need to keep proc or monitor
          rescue StandardError
            # clear config variable if failed, so next request tries again
            @active_scaffold_config = nil
            raise
          end
        end
      end

      def config_active_scaffold_delayed
        @delayed_monitor&.synchronize do
          # if called in same thread while running config, do nothing
          @active_scaffold_delayed&.call unless @active_scaffold_config
        end
      end

      def active_scaffold_config
        config_active_scaffold_delayed
        super
      end
    end
  end
end
