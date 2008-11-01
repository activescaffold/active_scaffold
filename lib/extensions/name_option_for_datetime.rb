module ActionView
  module Helpers
    class InstanceTag
      private

      # patch in support for options[:name]
      def options_with_prefix_with_name(position, options)
        if options[:name]
          options.merge(:prefix => options[:name].dup.insert(-2, "(#{position}i)"))
        else
          options_with_prefix_without_name(position, options)
        end
      end
      alias_method_chain :options_with_prefix, :name
    end
  end
end