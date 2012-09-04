module ActiveScaffold::DataStructures
  class NestedInfo
    def self.get(model, params)
      nested_info = {}
      begin
        unless params[:association].nil?
          ActiveScaffold::DataStructures::NestedInfoAssociation.new(model, params)
        else
          ActiveScaffold::DataStructures::NestedInfoScope.new(model, params)
        end
      rescue ActiveScaffold::ControllerNotFound
        nil
      end
    end
    
    attr_accessor :association, :child_association, :parent_model, :parent_scaffold, :parent_id, :param_name, :constrained_fields, :scope
        
    def initialize(model, params)
      @parent_scaffold = "#{params[:parent_scaffold].to_s.camelize}Controller".constantize
      @parent_model = @parent_scaffold.active_scaffold_config.model
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
      @parent_scope ||= parent_model.find(parent_id)
    end
    
    def habtm?
      false 
    end

    def has_many?
      false
    end

    def belongs_to?
      false
    end

    def has_one?
      false
    end

    def singular_association?
      belongs_to? || has_one?
    end

    def plural_association?
      has_many? || habtm?
    end

    def through_association?
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
    def initialize(model, params)
      super
      @association = parent_model.reflect_on_association(params[:association].to_sym)
      @param_name = @association.active_record.name.foreign_key.to_sym
      @parent_id = params[@param_name]
      iterate_model_associations(model)
    end
    
    def name
      self.association.name
    end
    
    def has_many?
      association.macro == :has_many 
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
    
    def through_association?
      association.options[:through]
    end
    
    def readonly?
      association.options[:readonly]
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
      @constrained_fields = Set.new
      constrained_fields << association.foreign_key.to_sym unless association.belongs_to?
      model.reflect_on_all_associations.each do |current|
        if association != current && association.foreign_key.to_s == current.foreign_key.to_s
          if current.belongs_to? && current.options[:polymorphic] && association.options[:as]
            @child_association = current if association.options[:as].to_sym == current.name
          elsif current.klass == @parent_model
            @child_association = current
          end
        end
      end
      constrained_fields << @child_association.name.to_sym
      @constrained_fields = @constrained_fields.to_a
    end
  end
  
  class NestedInfoScope < NestedInfo
    def initialize(model, params)
      super
      @scope = params[:named_scope].to_sym
      @param_name = parent_model.name.foreign_key.to_sym
      @parent_id = params[@param_name]
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
