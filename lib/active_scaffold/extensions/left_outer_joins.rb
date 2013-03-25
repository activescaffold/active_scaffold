module ActiveScaffold
  module OuterJoins
    def outer_joins(*assocs)
      joins(outer_joins_sql(*assocs))
    end

    private
    def outer_joins_sql(*assocs)
      assocs.collect do |assoc|
        if assoc.is_a? Array
          outer_joins_sql(*assoc)
        elsif assoc.is_a? Hash
          assoc.collect do |key, val|
            [left_outer_join_sql(key), klass.reflect_on_association(key).klass.outer_joins_sql(*val)]
          end
        elsif assoc.is_a? Symbol
          left_outer_join_sql(assoc)
        elsif assoc
          assoc
        end
      end.flatten.compact
    end

    def left_outer_join_sql(association_name)
      t = ActiveRecord::Associations::JoinDependency.new(klass, association_name, []).join_associations.first.join_relation(klass).arel
      t.joins(t)
    end
  end
end
ActiveRecord::Relation.send :include, ActiveScaffold::OuterJoins
module ActiveRecord::Querying
  delegate :outer_joins, :outer_joins_sql, :to => :scoped
end
