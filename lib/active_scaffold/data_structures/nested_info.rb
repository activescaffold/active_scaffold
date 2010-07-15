module ActiveScaffold::DataStructures
  class NestedInfo
    def self.get(model, session_storage)
      if session_storage[:nested].nil? 
        nil
      else
        ActiveScaffold::DataStructures::NestedInfo.new(model, session_storage)
      end
    end
    
    attr_accessor :association, :child_association, :parent_model, :parent_id, :constrained_fields
    
    def initialize(model, session_storage)
      info = session_storage[:nested].clone
      @parent_model = info[:parent_model]
      @association = @parent_model.reflect_on_association(info[:name])
      @parent_id = info[:parent_id]
      iterate_model_associations(model)
    end
    
    def new_instance?
      result = @new_instance.nil?
      @new_instance = false
      result
    end
    
    def parent_scope
      parent_model.find(parent_id)
    end
    
    def habtm?
      association.macro == :has_and_belongs_to_many 
    end
    
    def belongs_to?
      association.belongs_to?
    end
    
    def readonly?
      if association.options.has_key? :readonly
        association.options[:readonly]
      else
        association.options.has_key? :through
      end
    end
    
    protected
    def iterate_model_associations(model)
      @constrained_fields = [] 
      @constrained_fields << association.primary_key_name.to_sym unless association.belongs_to?
      model.reflect_on_all_associations.each do |current|
        if !current.belongs_to? && association.primary_key_name == current.association_foreign_key
          constrained_fields << current.name.to_sym
          @child_association = current
        end
        if association.primary_key_name == current.primary_key_name
          # show columns for has_many and has_one child associationes
          constrained_fields << current.name.to_sym if current.belongs_to? 
          @child_association = current
        end
      end
    end
 
    
  end
end
