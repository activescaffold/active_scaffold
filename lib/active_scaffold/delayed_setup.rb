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
            unless @active_scaffold_config # avoid running again if config is set (e.g. call active_scaffold_config inside block)
              @_prefixes = nil # clean prefixes in case is already cached, so our local_prefixes override is picked up
              super(model_id, &block)
            end
          rescue StandardError
            # clear config variable if failed, so next request tries again
            @active_scaffold_config = nil
            raise
          end
        end
      end

      def config_active_scaffold_delayed
        @delayed_monitor&.synchronize do
          @active_scaffold_delayed&.call
          @active_scaffold_delayed = nil if @active_scaffold_config # cleared only if config was set
        end
        @delayed_monitor = nil if @active_scaffold_config # cleared only when config was loaded successfully
      end

      def active_scaffold_config
        config_active_scaffold_delayed
        super
      end
    end
  end
end
