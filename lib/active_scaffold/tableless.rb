class ActiveScaffold::Tableless < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
  class AssociationScope < ActiveRecord::Associations::AssociationScope
    INSTANCE = create
    def self.scope(association, connection)
      INSTANCE.scope association, connection
    end
  end

  class Connection < ActiveRecord::ConnectionAdapters::AbstractAdapter
    attr_reader :klass
    def initialize(klass, *args)
      super(nil, *args)
      @klass = klass
    end

    def columns(table_name)
      klass.columns
    end

    def data_sources
      klass ? [klass.table_name] : []
    end
  end

  class Column < ActiveRecord::ConnectionAdapters::Column
    def initialize(name, default, sql_type = nil, null = true, **)
      metadata = ActiveRecord::Base.connection.send :fetch_type_metadata, sql_type
      super(name, default, metadata, null)
    end
  end

  module Tableless
    def skip_statement_cache?(scope)
      klass < ActiveScaffold::Tableless ? true : super
    end

    def target_scope
      super.tap do |scope|
        if klass < ActiveScaffold::Tableless
          class << scope; include RelationExtension; end
          assoc_conditions = scope.proxy_association&.send(:association_scope)&.conditions
          if assoc_conditions&.present?
            scope.conditions.concat(assoc_conditions.map { |c| c.is_a?(Hash) ? c[klass.table_name] || c : c })
          end
        end
      end
    end
  end

  module Association
    def self.included(base)
      base.prepend Tableless
    end
  end

  module TablelessCollectionAssociation
    def get_records # rubocop:disable Naming/AccessorMethodName
      klass < ActiveScaffold::Tableless ? scope.to_a : super
    end
  end

  module CollectionAssociation
    def self.included(base)
      base.prepend TablelessCollectionAssociation
    end
  end

  module TablelessSingularAssociation
    def get_records # rubocop:disable Naming/AccessorMethodName
      klass < ActiveScaffold::Tableless ? scope.limit(1).to_a : super
    end
  end

  module SingularAssociation
    def self.included(base)
      base.prepend TablelessSingularAssociation
    end
  end

  module RelationExtension
    def initialize(klass, *)
      super
      @conditions ||= []
    end

    def initialize_copy(other)
      @conditions = @conditions&.dup || []
      super
    end

    def conditions
      @conditions ||= []
    end

    def where(opts, *rest)
      if opts.present?
        opts = opts.with_indifferent_access if opts.is_a? Hash
        @conditions << (rest.empty? ? opts : [opts, *rest])
      end
      self
    end
    alias where! where

    def merge(rel)
      super.tap do |merged|
        merged.conditions.concat rel.conditions unless rel.nil? || rel.is_a?(Array)
      end
    end

    def except(*skips)
      super.tap do |new_relation|
        unless new_relation.is_a?(RelationExtension)
          class << new_relation; include RelationExtension; end
        end
        new_relation.conditions.concat conditions unless skips.include? :where
      end
    end

    def find_one(id)
      @klass.find_one(id, self) || raise(ActiveRecord::RecordNotFound)
    end

    def execute_simple_calculation(operation, column_name, distinct)
      @klass.execute_simple_calculation(self, operation, column_name, distinct)
    end

    def implicit_order_column
      @klass.implicit_order_column
    end

    def exists?
      size.positive?
    end

    private

    def exec_queries
      @records = @klass.find_all(self)
      @loaded = true
      @records
    end
  end

  class Relation < ::ActiveRecord::Relation
    include RelationExtension
  end
  class << self

    def find(*ids)
      ids.length == 1 ? all.find(*ids[0]) : super
    end

    private

    def relation
      ActiveScaffold::Tableless::Relation.new(self)
    end

    def cached_find_by_statement(key, &block)
      StatementCache.new(key, self, &block)
    end
  end

  class StatementCache
    def initialize(key, model = nil)
      @key = key
      @model = model
    end

    def execute(values, connection)
      @model.where(@key => values)
    end
  end

  def self.columns
    @tableless_columns ||= []
  end

  def self.table_name
    @table_name ||= ActiveModel::Naming.plural(self)
  end

  def self.table_exists?
    true
  end
  self.abstract_class = true

  def self.connection
    @connection ||= Connection.new(self)
  end

  def self.column(name, sql_type = nil, options = {})
    column = Column.new(name.to_s, options[:default], sql_type.to_s, options.key?(:null) ? options[:null] : true)
    column.tap { columns << column }
  end

  def self.find_all(relation)
    raise 'self.find_all must be implemented in a Tableless model'
  end

  def self.find_one(id, relation)
    raise 'self.find_one must be implemented in a Tableless model'
  end

  def self.execute_simple_calculation(relation, operation, column_name, distinct)
    unless operation == 'count' && [relation.klass.primary_key, :all].include?(column_name)
      raise "self.execute_simple_calculation must be implemented in a Tableless model to support #{operation} #{column_name}#{' distinct' if distinct} columns"
    end
    find_all(relation).size
  end

  def destroy
    raise 'destroy must be implemented in a Tableless model'
  end

  def _create_record #:nodoc:
    run_callbacks(:create) {}
  end

  def _update_record(*) #:nodoc:
    run_callbacks(:update) {}
  end
end
