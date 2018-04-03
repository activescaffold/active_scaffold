if Rails.version < '5.0.0'
  module ActiveScaffold
    module OuterJoins
      extend ActiveSupport::Concern

      def left_outer_joins_values
        @values[:left_outer_joins] || []
      end

      def left_outer_joins_values=(values)
        raise ImmutableRelation if @loaded
        @values[:left_outer_joins] = values
      end

      def left_outer_joins(*args)
        check_if_method_has_arguments!('left_outer_joins', args)
        spawn.left_outer_joins!(*args.compact.flatten)
      end
      alias left_joins left_outer_joins

      def outer_joins(*args)
        ActiveSupport::Deprecation.warn 'use left_outer_joins or left_joins which is added to Rails 5.0.0'
        left_outer_joins(*args)
      end

      def left_outer_joins!(*args)
        self.joins_values += [''] # HACK: for using left_outer_joins in update_all/delete_all
        self.left_outer_joins_values += args
        self
      end
      alias left_joins! left_outer_joins!

      def outer_joins!(*args)
        ActiveSupport::Deprecation.warn 'use left_outer_joins! or left_joins! which is added to Rails 5.0.0'
        left_outer_joins!(*args)
      end

      def build_arel
        if left_outer_joins_values.empty?
          super
        else
          relation = except(:left_outer_joins)
          relation.joins! ActiveRecord::Associations::JoinDependency.new(@klass, left_outer_joins_values, [])
          relation.build_arel
        end
      end
    end
  end
  ActiveRecord::Relation.send :include, ActiveScaffold::OuterJoins
  module ActiveRecord::Querying
    delegate :left_outer_joins, :left_joins, :outer_joins, :to => :all
  end
end
