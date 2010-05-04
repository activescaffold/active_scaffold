module ActiveScaffold
  module MarkedModel
    # This is a module aimed at making the make session_stored marked_records available to ActiveRecord models
    
    def self.included(base)
      base.extend ClassMethods
      base.named_scope :marked, lambda {{:conditions => {:id => base.marked_records.to_a}}}
    end
    
    def marked
      marked_records.include?(self.id)
    end
    
    def marked=(value)
      value = (value.downcase == 'true') if value.is_a? String 
      if value == true
        marked_records << self.id if !marked
      else
        marked_records.delete(self.id)
      end
    end
  
    module ClassMethods
      # The proc to call that retrieves the marked_records from the ApplicationController.
      attr_accessor :marked_records_proc
  
      # Class-level access to the marked_records
      def marked_records
        (marked_records_proc.call || Set.new) if marked_records_proc
      end
    end
  
    # Instance-level access to the marked_records
    def marked_records
      self.class.marked_records
    end
  end
end
