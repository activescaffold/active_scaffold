module ActiveScaffold
  module MarkedModel
    # This is a module aimed at making the make session_stored marked_records available to ActiveRecord models
    
    def self.included(base)
      base.extend ClassMethods
      base.scope :as_marked, lambda { where(:id => base.marked_records.to_a) }
    end
    
    def as_marked
      marked_records.include?(self.id)
    end
    
    def as_marked=(value)
      value = [true, 'true', 1, '1', 'T', 't'].include?(value.class == String ? value.downcase : value)
      if value == true
        marked_records << self.id if !as_marked
      else
        marked_records.delete(self.id)
      end
    end
  
    module ClassMethods
      def marked_records
        Thread.current[:marked_records] ||= Set.new
      end

      def marked_records=(marked)
        Thread.current[:marked_records] = marked 
      end
    end
  
    # Instance-level access to the marked_records
    def marked_records
      self.class.marked_records
    end
  end
end
