module ActiveScaffold::DataStructures
  class NestedInfo
    def self.get(model, session_storage)
      if session_storage[:nested].nil? 
        nil
      else
        session_info = session_storage[:nested].clone
        begin
          session_info[:parent_scaffold] = "#{session_info[:parent_scaffold].to_s.camelize}Controller".constantize
          session_info[:parent_model] = session_info[:parent_scaffold].active_scaffold_config.model
          session_info[:association] = session_info[:parent_model].reflect_on_association(session_info[:name])
          unless session_info[:association].nil?
            ActiveScaffold::DataStructures::NestedInfoAssociation.new(model, session_info)
          else
            ActiveScaffold::DataStructures::NestedInfoScope.new(model, session_info)
          end
        rescue ActiveScaffold::ControllerNotFound
          nil
        end
      end
    end
    
    attr_accessor :association, :child_association, :parent_model, :parent_scaffold, :parent_id, :constrained_fields, :scope
        
    def initialize(model, session_info)
      @parent_model = session_info[:parent_model]
      @parent_id = session_info[:parent_id]
      @parent_scaffold = session_info[:parent_scaffold]
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
      false 
    end
    
    def belongs_to?
      false
    end

    def has_one?
      false
    end
    
    def readonly?
      false
    end

    def sorted?
      false
    end
  end
  
  class NestedInfoAssociation < NestedInfo
    def initialize(model, session_info)
      super(model, session_info)
      @association = session_info[:association]
      iterate_model_associations(model)
    end
    
    def habtm?
      association.macro == :has_and_belongs_to_many 
    end
    
    def belongs_to?
      association.belongs_to?
    end

    def has_one?
      association.macro == :has_one
    end
    
    def readonly?
      if association.options.has_key? :readonly
        association.options[:readonly]
      else
        association.options.has_key? :through
      end
    end

    def sorted?
      association.options.has_key? :order
    end

    def default_sorting
      association.options[:order]
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
  
  class NestedInfoScope < NestedInfo
    def initialize(model, session_info)
      super(model, session_info)
      @scope = session_info[:name]
      @constrained_fields = [] 
    end
  end
end
