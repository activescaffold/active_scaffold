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

      class ActionColumns < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::ActionColumns)
        attr_writer :columns

        def each(options = {}, &proc)
          __getobj__.each(options) do |column|
            if column.is_a?(::ActiveScaffold::DataStructures::ActionColumns)
              column = __wrap__(column)
              column.columns = @columns
            else
              column = @columns[column.name]
            end
            yield column
          end
        end
      end

      class ActionLinks < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::ActionLinks)
        def method_missing(name, *args, &block)
          __copy_on_write__ if frozen?
          subgroup =
            if _instance_variable_defined?("@#{name}")
              _instance_variable_get("@#{name}")
            else
              _instance_variable_set("@#{name}", __wrap__(__getobj__.subgroup(name, args.first)))
            end
          yield subgroup if block
          subgroup
        end
      end
    end
  end
end
