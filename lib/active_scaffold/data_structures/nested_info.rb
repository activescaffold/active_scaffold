# frozen_string_literal: true

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
      {parent_scaffold: parent_scaffold.controller_path}
    end

    def new_instance?
      result = @new_instance.nil?
      @new_instance = false
      result
    end

    def habtm?
      false
    end

    def has_many? # rubocop:disable Naming/PredicatePrefix
      false
    end

    def belongs_to?
      false
    end

    def has_one? # rubocop:disable Naming/PredicatePrefix
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

    def create_with_parent?
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

    delegate :name, :belongs_to?, :has_one?, :has_many?, :habtm?, :readonly?, to: :association

    # A through association with has_one or has_many as source association
    # create cannot be called in nested through associations, and not-nested through associations, unless:
    # 1. is through singular and source association has reverse, e.g.:
    #    Employee belongs to vendor, Vendor has many rates, Rate belongs to vendor, Employee has many rates through vendor
    #    Rates association through singular association vendor, source association in Vendor (rates) has reverse (vendor in Rate)
    #    AS will assign the vendor of the employee to the new Rate
    # 2. source association is singular, e.g.:
    #    Customer has many networks, Network has one (or belongs to) firewall, Customer has many firewalls through networks
    # 3. create columns include through association of reverse association, e.g.:
    #    Vendor has many employees, Employee has many rates, Vendor has many rates through employees, Rate has one vendor through employee
    #    RatesController has employee in create action columns (reverse is vendor, and through association employee is in create form).
    def readonly_through_association?(columns)
      return false unless through_association?
      return true if association.through_reflection.options[:through] # create not possible, too many levels
      return true if association.source_reflection.options[:through] # create not possible, too many levels
      return false if create_through_singular? # create allowed, AS has code for this
      return false unless association.source_reflection.collection? # create allowed if source is singular, rails creates joint model

      # create allowed only if through reflection in record to be created is included in create columns
      !child_association || columns.exclude?(child_association.through_reflection.name)
    end

    def create_through_singular?
      association.through_singular? && source_reflection.reverse
    end

    def create_with_parent?
      if has_many? && !association.through?
        false
      elsif child_association || create_through_singular?
        true
      end
    end

    def source_reflection
      @source_reflection ||= ActiveScaffold::DataStructures::Association::ActiveRecord.new(association.source_reflection)
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
      super.merge(association: @association.name, @param_name => parent_id)
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
      super.merge(named_scope: @scope)
    end

    def name
      scope
    end
  end
end
