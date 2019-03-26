require 'cow_proxy'

module CowProxy
  module ActiveScaffold
    module DataStructures
      class Column < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::Column)
      end

      class Set < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::Set)
        protected

        # Copy wrapped values to duplicated wrapped object
        # @see CowProxy::Base#__copy_on_write__
        # @return duplicated wrapped object
        def __copy_on_write__(*)
          super.tap do
            new_set = __getobj__.instance_variable_get(:@set).dup
            __getobj__.instance_variable_set(:@set, new_set)
          end
        end
      end

      class ActionLinks < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::ActionLinks)
        def method_missing(name, *args, &block)
          puts "method missing #{name} in #{__getobj__.name}" if ENV['DEBUG']
          return super if name =~ /[!?]$/
          subgroup =
            if _instance_variable_defined?("@#{name}")
              _instance_variable_get("@#{name}")
            else
              __copy_on_write__ if __getobj__.frozen?
              group = __getobj__.subgroup(name, args.first)
              puts "created subgroup #{group.name}" if ENV['DEBUG'] && !group.frozen?
              group = __wrap__(group) if group.frozen?
              _instance_variable_set("@#{name}", group)
            end
          yield subgroup if block
          subgroup
        end

        def respond_to_missing?(name, *)
          name !~ /[!?]$/
        end

        protected

        # Copy wrapped values to duplicated wrapped object
        # @see CowProxy::Base#__copy_on_write__
        # @return duplicated wrapped object
        def __copy_on_write__(*)
          index = @parent_proxy.instance_variable_get(:@set).index(__getobj__) if @parent_proxy
          super.tap do
            puts "replace #{index} with proxy obj in parent #{@parent_proxy.name}" if ENV['DEBUG'] && index
            @parent_proxy.instance_variable_get(:@set)[index] = self if index
            new_set = __getobj__.instance_variable_get(:@set).dup
            __getobj__.instance_variable_set(:@set, new_set)
          end
        end
      end
    end
  end
end
