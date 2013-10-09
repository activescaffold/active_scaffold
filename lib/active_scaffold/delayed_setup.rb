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
        @active_scaffold_delayed = proc{ super(model_id, &block) }
      end

      def config_active_scaffold_delayed
        if @active_scaffold_delayed
          block, @active_scaffold_delayed = @active_scaffold_delayed, nil
          block.call
        end
      end

      def active_scaffold_config
        config_active_scaffold_delayed
        super
      end
    end
  end
end
