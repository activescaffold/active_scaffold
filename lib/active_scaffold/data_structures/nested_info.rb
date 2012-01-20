module ActiveScaffold::DataStructures
  class NestedInfo
    def self.get(model, params)
      nested_info = {}
      begin
        nested_info[:name] = (params[:association] || params[:named_scope]).to_sym
        nested_info[:parent_scaffold] = "#{params[:parent_scaffold].to_s.camelize}Controller".constantize
        nested_info[:parent_model] = nested_info[:parent_scaffold].active_scaffold_config.model
        nested_info[:parent_id] = params[nested_info[:parent_model].name.foreign_key]
        if nested_info[:parent_id]
          unless nested_info[:association].nil?
            ActiveScaffold::DataStructures::NestedInfoAssociation.new(model, nested_info)
          else
            ActiveScaffold::DataStructures::NestedInfoScope.new(model, nested_info)
          end
        end
      rescue ActiveScaffold::ControllerNotFound
        nil
      end
    end
    
    attr_accessor :association, :child_association, :parent_model, :parent_scaffold, :parent_id, :constrained_fields, :scope
        
    def initialize(model, nested_info)
      @parent_model = nested_info[:parent_model]
      @parent_id = nested_info[:parent_id]
      @parent_scaffold = nested_info[:parent_scaffold]
    end
    
    def to_params
      {:parent_scaffold => parent_scaffold.controller_path}
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
    def initialize(model, nested_info)
      super(model, nested_info)
      @association = parent_model.reflect_on_association(nested_info[:name])
      iterate_model_associations(model)
    end
    
    def name
      self.association.name
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
    
    def to_params
      super.merge(:association => @association.name, :assoc_id => parent_id)
    end
    
    protected
    
    def iterate_model_associations(model)
      @constrained_fields = [] 
      @constrained_fields << association.foreign_key.to_sym unless association.belongs_to?
      model.reflect_on_all_associations.each do |current|
        if !current.belongs_to? && association.foreign_key == current.association_foreign_key
          constrained_fields << current.name.to_sym
          @child_association = current if current.klass == @parent_model
        end
        if association.foreign_key == current.foreign_key
          # show columns for has_many and has_one child associationes
          constrained_fields << current.name.to_sym if current.belongs_to? 
          @child_association = current if current.klass == @parent_model
        end
      end
    end
  end
  
  class NestedInfoScope < NestedInfo
    def initialize(model, nested_info)
      super(model, nested_info)
      @scope = nested_info[:name]
      @constrained_fields = [] 
    end
    
    def to_params
      super.merge(:named_scope => @scope)
    end
    
    def name
      self.scope
    end
  end
end
