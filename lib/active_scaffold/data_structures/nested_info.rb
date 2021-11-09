module ActiveScaffold::DataStructures
  class NestedInfo
    def self.get(model, params)
      if params[:association].nil?
        ActiveScaffold::DataStructures::NestedInfoScope.new(model, params)
      else
        ActiveScaffold::DataStructures::NestedInfoAssociation.new(model, params)
      end
    rescue ActiveScaffold::ControllerNotFound
      nil
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

    def habtm?
      false
    end

    def has_many? # rubocop:disable Naming/PredicateName
      false
    end

    def belongs_to?
      false
    end

    def has_one? # rubocop:disable Naming/PredicateName
      false
    end

    def singular_association?
      belongs_to? || has_one?
    end

    def plural_association?
      has_many? || habtm?
    end

    def readonly_through_association?(columns)
      false
    end

    def through_association?
      false
    end

    def readonly?
      false
    end

    def sorted?(*)
      false
    end

    def match_model?(model)
      false
    end
  end

  class NestedInfoAssociation < NestedInfo
    def initialize(model, params)
      super
      column = parent_scaffold.active_scaffold_config.columns[params[:association].to_sym]
      @param_name = column.model.name.foreign_key.to_sym
      @parent_id = params[@param_name]
      @association = column&.association
      @child_association = association.reverse_association(model) if association
      setup_constrained_fields
    end

    delegate :name, :belongs_to?, :has_one?, :has_many?, :habtm?, :readonly?, :to => :association

    # A through association with has_one or has_many as source association
    # create cannot be called in nested through associations, and not-nested through associations
    # unless is through singular or create columns include through reflection of reverse association
    # e.g. customer -> networks -> firewall, reverse is firewall -> network -> customer,
    # firewall can be created if create columns include network
    def readonly_through_association?(columns)
      return false unless through_association?
      return true if association.through_reflection.options[:through] # create not possible, too many levels
      return true if association.source_reflection.options[:through] # create not possible, too many levels
      return false if association.through_singular? # create allowed, AS has code for this

      # create allowed only if through reflection in record to be created is included in create columns
      !child_association || !columns.include?(child_association.through_reflection.name)
    end

    def through_association?
      association.through?
    end

    def match_model?(model)
      if association.polymorphic?
        child_association&.inverse_klass == model
      else
        association.klass == model
      end
    end

    def sorted?(chain)
      default_sorting(chain).present?
    end

    def default_sorting(chain)
      return @default_sorting if defined? @default_sorting
      return unless association.scope.is_a?(Proc) && chain.respond_to?(:values) && chain.values[:order]
      @default_sorting = chain.values[:order]
      @default_sorting = @default_sorting.map(&:to_sql) if @default_sorting[0].is_a? Arel::Nodes::Node
      @default_sorting = @default_sorting.join(', ')
    end

    def to_params
      super.merge(:association => @association.name, @param_name => parent_id)
    end

    protected

    def setup_constrained_fields
      @constrained_fields = [] if association.belongs_to? || association.through?
      @constrained_fields ||= Array(association.foreign_key).map(&:to_sym)
      return unless child_association && child_association != association

      @constrained_fields << child_association.name
      @constrained_fields << child_association.foreign_type.to_sym if child_association.polymorphic?
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
      scope
    end
  end
end
