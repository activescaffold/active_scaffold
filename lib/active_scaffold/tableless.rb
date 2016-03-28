class ActiveScaffold::Tableless < ActiveRecord::Base
  class AssociationScope < ActiveRecord::Associations::AssociationScope
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

    if defined?(ActiveRecord::Associations::AssociationScope::INSTANCE) # rails >= 4.1
      INSTANCE = respond_to?(:create) ? create : new # create for rails >= 4.2
      def self.scope(association, connection)
        INSTANCE.scope association, connection
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
  end

  class Column < ActiveRecord::ConnectionAdapters::Column
    if instance_method(:initialize).arity == -4 # rails >= 4.2
      def initialize(name, default, sql_type = nil, null = true)
        cast_type = ActiveRecord::Base.connection.send :lookup_cast_type, sql_type
        super(name, default, cast_type, sql_type, null)
      end
    end
  end

  module Association
    def self.included(base)
      base.alias_method_chain :association_scope, :tableless
      base.alias_method_chain :target_scope, :tableless
    end

    def association_scope_with_tableless
      @association_scope ||= overrided_association_scope if klass < ActiveScaffold::Tableless
      association_scope_without_tableless
    end

    def overrided_association_scope
      if AssociationScope.respond_to?(:scope) # rails >= 4.1
        AssociationScope.scope(self, klass.connection)
      else # rails < 4.1
        AssociationScope.new(self).scope
      end
    end

    def target_scope_with_tableless
      target_scope_without_tableless.tap do |scope|
        if klass < ActiveScaffold::Tableless
          class << scope; include RelationExtension; end
        end
      end
    end
  end

  module CollectionAssociation
    def self.included(base)
      base.alias_method_chain :get_records, :tableless if Rails.version >= '4.2'
    end
    def get_records_with_tableless
      klass < ActiveScaffold::Tableless ? scope.to_a : get_records_without_tableless
    end
  end

  module SingularAssociation
    def self.included(base)
      base.alias_method_chain :get_records, :tableless if Rails.version >= '4.2'
    end
    def get_records_with_tableless
      klass < ActiveScaffold::Tableless ? scope.limit(1).to_a : get_records_without_tableless
    end
  end

  module RelationExtension
    attr_reader :conditions

    def initialize(klass, table)
      super
      @conditions ||= []
    end

    def initialize_copy(other)
      @conditions = @conditions.try(:dup) || []
      super
    end

    def where(opts, *rest)
      unless opts.blank?
        opts = opts.with_indifferent_access if opts.is_a? Hash
        @conditions << (rest.empty? ? opts : [opts, *rest])
      end
      self
    end

    def merge(r)
      super.tap do |merged|
        merged.conditions.concat r.conditions unless r.nil? || r.is_a?(Array)
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
      ActiveScaffold::Tableless::Relation.new(self, arel_table)
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

  unless Rails.version < '4.2'
    def self.columns_hash
      if self < ActiveScaffold::Tableless
        @columns_hash ||= Hash[columns.map { |c| [c.name, c] }]
      else
        super
      end
    end
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
  alias_method :create_record, :_create_record # for rails4 < 4.0.6, < 4.1.2
  alias_method :create, :_create_record # for rails3

  def _update_record(*) #:nodoc:
    run_callbacks(:update) {}
  end
  alias_method :update_record, :_update_record # for rails4 < 4.0.6, < 4.1.2
  alias_method :update, :_update_record # for rails3
end
