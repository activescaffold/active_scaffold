module ActiveRecord
  module Associations
    JoinDependency.class_eval do

      def initialize(base, associations, joins, join_type = Arel::InnerJoin)
        if Rails::VERSION::MAJOR < 4
          @active_record = base
        else
          @base_klass = base
        end
        @table_joins   = joins
        @join_parts    = [ActiveRecord::Associations::JoinDependency::JoinBase.new(base)]
        @associations  = {}
        @reflections   = []
        @alias_tracker = AliasTracker.new(base.connection, joins)
        @alias_tracker.aliased_name_for(base.table_name) # Updates the count for base.table_name to 1
        build(associations, nil, join_type)
      end
    end
  end
end

module ActiveScaffold
  module OuterJoins
    extend ActiveSupport::Concern
    attr_accessor :outer_joins_values

    if Rails::VERSION::MAJOR < 4
      included do
        const_get(:MULTI_VALUE_METHODS) << :outer_joins_values
      end

      def outer_joins(*args)
        return self if args.compact.blank?

        relation = clone

        args.flatten!
        relation.joins_values += [''] # HACK for using outer_joins in update_all/delete_all
        relation.outer_joins_values += args

        relation
      end
    else
      def outer_joins_values
        @values[:outer_joins] || []
      end

      def outer_joins_values=(values)
        raise ImmutableRelation if @loaded
        @values[:outer_joins] = values
      end

      def outer_joins(*args)
        check_if_method_has_arguments!("outer_joins", args)
        spawn.outer_joins!(*args.compact.flatten)
      end

      def outer_joins!(*args)
        self.joins_values += [''] # HACK for using outer_joins in update_all/delete_all
        self.outer_joins_values += args
        self
      end
    end

    def build_arel
      arel = super
      build_joins(arel, outer_joins_values, Arel::OuterJoin) unless outer_joins_values.empty?
      arel
    end

    protected
    
    def build_joins(manager, joins, join_type = Arel::InnerJoin)
      buckets = joins.group_by do |join|
        case join
        when String
          :string_join
        when Hash, Symbol, Array
          :association_join
        when ActiveRecord::Associations::JoinDependency::JoinAssociation
          :stashed_join
        when Arel::Nodes::Join
          :join_node
        else
          raise 'unknown class: %s' % join.class.name
        end
      end

      association_joins         = buckets[:association_join] || []
      stashed_association_joins = buckets[:stashed_join] || []
      join_nodes                = (buckets[:join_node] || []).uniq
      string_joins              = (buckets[:string_join] || []).map { |x| x.strip }.uniq

      join_list = join_nodes + custom_join_ast(manager, string_joins)

      join_dependency = ActiveRecord::Associations::JoinDependency.new(
        @klass,
        association_joins,
        join_list,
        join_type
      )

      join_dependency.graft(*stashed_association_joins)

      @implicit_readonly = true unless association_joins.empty? && stashed_association_joins.empty?

      # FIXME: refactor this to build an AST
      join_dependency.join_associations.each do |association|
        association.join_to(manager)
      end

      manager.join_sources.concat join_list

      manager
    end

  end
end
ActiveRecord::Relation.send :include, ActiveScaffold::OuterJoins
module ActiveRecord::Querying
  delegate :outer_joins, :to => Rails::VERSION::MAJOR < 4 ? :scoped : :all
end
