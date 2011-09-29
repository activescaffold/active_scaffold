module ActiveRecord
  class Relation
    def target=(records)
      debugger
      @loaded = true
      @records = records
      puts loaded?.inspect
      puts self.object_id
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
