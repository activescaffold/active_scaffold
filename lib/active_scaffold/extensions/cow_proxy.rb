require 'cow_proxy'

module CowProxy
  module ActiveScaffold
    module DataStructures
      class Column < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::Column)
      end

      class Set < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::Set)
        include Indexable
      end

      class ActionColumns < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::ActionColumns)
        attr_writer :columns

        def each(options = {}, &proc)
          __getobj__.each do |column|
            yield @columns[column.name]
          end
        end
      end
    end
  end
end
