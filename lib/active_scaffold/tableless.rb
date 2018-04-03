class ActiveScaffold::Tableless < ActiveRecord::Base
  class AssociationScope < ActiveRecord::Associations::AssociationScope
    INSTANCE = create
    def self.scope(association, connection)
      INSTANCE.scope association, connection
    end

    if Rails.version < '5.0.0'
      def column_for(table_name, column_name, alias_tracker = nil)
        klass = alias_tracker ? alias_tracker.connection.klass : self.klass
        if table_name == klass.table_name
          klass.columns_hash[column_name]
        elsif alias_tracker && (klass = alias_tracker.instance_variable_get(:@assoc_klass))
          klass.columns_hash[column_name]
        else # rails < 4.1
          association.klass.columns_hash[column_name]
        end
      end

      def add_constraints(scope, owner, assoc_klass, refl, tracker)
        tracker.instance_variable_set(:@assoc_klass, assoc_klass)
        super
      end
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
  end

  class Column < ActiveRecord::ConnectionAdapters::Column
    if Rails.version >= '5.0.0'
      def initialize(name, default, sql_type = nil, null = true)
        metadata = ActiveRecord::Base.connection.send :fetch_type_metadata, sql_type
        super(name, default, metadata, null)
      end
    else
      def initialize(name, default, sql_type = nil, null = true)
        cast_type = ActiveRecord::Base.connection.send :lookup_cast_type, sql_type
        super(name, default, cast_type, sql_type, null)
      end
    end
  end

  module Tableless
    def association_scope
      @association_scope ||= AssociationScope.scope(self, klass.connection) if klass < ActiveScaffold::Tableless
      super
    end

    def target_scope
      super.tap do |scope|
        if klass < ActiveScaffold::Tableless
          class << scope; include RelationExtension; end
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
    def get_records
      klass < ActiveScaffold::Tableless ? scope.to_a : super
    end
  end

  module CollectionAssociation
    def self.included(base)
      base.prepend TablelessCollectionAssociation
    end
  end

  module TablelessSingularAssociation
    def get_records
      klass < ActiveScaffold::Tableless ? scope.limit(1).to_a : super
    end
  end

  module SingularAssociation
    def self.included(base)
      base.prepend TablelessSingularAssociation
    end
  end

  module RelationExtension
    attr_reader :conditions

    if Rails.version >= '5.0'
      def initialize(klass, table, predicate_builder, values = {})
        super
        @conditions ||= []
      end
    else
      def initialize(klass, table)
        super
        @conditions ||= []
      end
    end

    def initialize_copy(other)
      @conditions = @conditions&.dup || []
      super
    end

    def where(opts, *rest)
      if opts.present?
        opts = opts.with_indifferent_access if opts.is_a? Hash
        @conditions << (rest.empty? ? opts : [opts, *rest])
      end
      self
    end

    def merge(rel)
      super.tap do |merged|
        merged.conditions.concat rel.conditions unless rel.nil? || rel.is_a?(Array)
      end
    end

    def except(*skips)
      super.tap do |new_relation|
        new_relation.conditions = conditions unless skips.include? :where
      end
    end

    def to_a
      @klass.find_all(self)
    end

    def find_one(id)
      @klass.find_one(id, self) || raise(ActiveRecord::RecordNotFound)
    end

    def execute_simple_calculation(operation, column_name, distinct)
      @klass.execute_simple_calculation(self, operation, column_name, distinct)
    end
  end

  class Relation < ActiveRecord::Relation
    include RelationExtension
  end
  class << self
    private

    def relation
      args = [self, arel_table]
      args << predicate_builder if Rails.version >= '5.0.0'
      ActiveScaffold::Tableless::Relation.new(*args)
    end
  end

  class StatementCache
    def initialize(key)
      @key = key
    end

    def execute(values, model, connection)
      model.where(@key => values)
    end
  end

  def self.columns_hash
    if self < ActiveScaffold::Tableless
      @columns_hash ||= Hash[columns.map { |c| [c.name, c] }]
    else
      super
    end
  end
  if Rails.version >= '5.0'
    def self.initialize_find_by_cache
      @find_by_statement_cache = {
        true => Hash.new { |h, k| h[k] = StatementCache.new(k) },
        false => Hash.new { |h, k| h[k] = StatementCache.new(k) }
      }
    end
  else
    def self.initialize_find_by_cache
      self.find_by_statement_cache = Hash.new { |h, k| h[k] = StatementCache.new(k) }
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
    if operation == 'count' && [relation.klass.primary_key, :all].include?(column_name)
      find_all(relation).size
    else
      raise "self.execute_simple_calculation must be implemented in a Tableless model to support #{operation} #{column_name}#{' distinct' if distinct} columns"
    end
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
