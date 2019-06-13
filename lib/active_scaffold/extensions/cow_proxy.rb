require 'cow_proxy'

module CowProxy
  module ActiveScaffold
    module DataStructures
      class Column < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::Column)
        delegate :name, to: :__getobj__

        def link
          return @link if defined?(@link)
          if __getobj__.frozen?
            link_var = __getobj__.instance_variable_get(:@link)
            if link_var.is_a?(Proc)
              @link = link_var.call self
              return @link
            end
          end
          super
        end
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

      class ActionColumns < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::ActionColumns)
      end

      class ActionLinks < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::ActionLinks)
        def method_missing(name, *args, &block)
          CowProxy.debug { "method missing #{name} in #{__getobj__.name}" }
          return super if name =~ /[!?]$/
          subgroup =
            if _instance_variable_defined?("@#{name}")
              _instance_variable_get("@#{name}")
            else
              __copy_on_write__ if __getobj__.frozen?
              group = __getobj__.subgroup(name, args.first)
              if group.frozen?
                group = __wrap__(group)
              else
                CowProxy.debug { "created subgroup #{group.name}" }
              end
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
            CowProxy.debug { "replace #{index} with proxy obj in parent #{@parent_proxy.name}" } if index
            @parent_proxy.instance_variable_get(:@set)[index] = self if index
            new_set = __getobj__.instance_variable_get(:@set).dup
            __getobj__.instance_variable_set(:@set, new_set)
          end
        end
      end
    end
  end
end
