# frozen_string_literal: true

module ActiveScaffold
  # Exposes a +configure+ method that accepts a block and runs all contents of the block in two contexts,
  # as opposed to the normal one. First, everything gets evaluated as part of the object including Configurable.
  # Then, as a failover, missing methods and variables are evaluated in the original binding of the block.
  #
  # Note that this only works with "barewords". Constants, instance variables, and class variables are not currently supported in both contexts.
  #
  # May add the given functionality at both the class and instance level. For the former, use +extend+, and for the latter, use +include+.
  module Configurable
    def configure(&configuration_block)
      return unless configuration_block

      @configuration_binding = configuration_block.binding.eval('self')
      ret = instance_exec(self, &configuration_block)
      @configuration_binding = nil
      ret
    end

    def method_missing(name, *)
      if @configuration_binding&.respond_to?(name, true) # rubocop:disable Lint/RedundantSafeNavigation
        @configuration_binding.send(name, *)
      else
        super
      end
    end

    def respond_to_missing?(name, include_all = false)
      if defined? @configuration_binding
        @configuration_binding&.respond_to?(name, include_all)
      else
        super
      end
    end
  end
end
