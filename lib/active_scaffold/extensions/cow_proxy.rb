require 'cow_proxy'

module CowProxy
  module ActiveScaffold
    module DataStructures
      class Column < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::Column)
      end
      class Set < ::CowProxy::WrapClass(::ActiveScaffold::DataStructures::Set)
        include Indexable
      end
    end
  end
end
