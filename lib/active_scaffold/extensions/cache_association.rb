module ActiveRecord
  class Relation
    def target=(records)
      @loaded = true
      @records = records
      @records
    end
  end
end
module ActiveRecord
  module Associations
    class CollectionProxy
      delegate :target=, :to => :@association
    end
  end
end
