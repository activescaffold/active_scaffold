module ActiveScaffold
  module OuterJoins
    extend ActiveSupport::Concern
    attr_accessor :outer_joins_values

    if Rails::VERSION::MAJOR < 4
      included do
        const_get(:MULTI_VALUE_METHODS) << :outer_joins
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

    if Rails.version < '4.1'
      def build_joins(manager, joins)
        manager = super
        unless outer_joins_values.empty?
          join_dependency = ActiveRecord::Associations::JoinDependency.new(@klass, outer_joins_values, [])
          join_dependency.join_associations.each do |association|
            association.join_to(manager)
          end
        end
        manager
      end
    else
      def build_joins(manager, joins)
        manager = super
        unless outer_joins_values.empty?
          join_dependency = ActiveRecord::Associations::JoinDependency.new(@klass, outer_joins_values, [])
          joins = join_dependency.join_constraints []
          joins.each { |join| manager.from(join) }
        end
        manager
      end
    end
  end
end
ActiveRecord::Relation.send :include, ActiveScaffold::OuterJoins
module ActiveRecord::Querying
  delegate :outer_joins, :to => Rails::VERSION::MAJOR < 4 ? :scoped : :all
end
