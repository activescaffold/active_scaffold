class ActiveScaffold::Tableless < ActiveRecord::Base
  class AssociationScope < ActiveRecord::Associations::AssociationScope
    def column_for(table_name, column_name)
      if table_name == klass.table_name
        klass.columns_hash[column_name]
      else
        super
      end
    end
  end

  module Association
    def self.included(base)
      base.alias_method_chain :association_scope, :tableless
      base.alias_method_chain :target_scope, :tableless
    end

    def association_scope_with_tableless
      @association_scope ||= AssociationScope.new(self).scope if klass < ActiveScaffold::Tableless
      association_scope_without_tableless
    end

    def target_scope_with_tableless
      target_scope_without_tableless.tap do |scope|
        if klass < ActiveScaffold::Tableless
          class << scope; include RelationExtension; end
        end
      end
    end
  end

  module RelationExtension
    def conditions
      @conditions
    end
  
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
      @klass.find_one(id, self) or raise ActiveRecord::RecordNotFound
    end

    def execute_simple_calculation(operation, column_name, distinct)
      @klass.execute_simple_calculation(self, operation, column_name, distinct)
    end
  end

  # For rails3
  class Relation < ActiveRecord::Relation
    include RelationExtension
  end

  def self.columns; @columns ||= []; end
  def self.table_name; @table_name ||= ActiveModel::Naming.plural(self); end
  def self.table_exists?; true; end
  self.abstract_class = true
  # For rails3
  class << self
    private
    def relation
      ActiveScaffold::Tableless::Relation.new(self, arel_table)
    end
  end

  def self.column(name, sql_type = nil, options = {})
    column = ActiveRecord::ConnectionAdapters::Column.new(name.to_s, options[:default], sql_type.to_s, options.has_key?(:null) ? options[:null] : true)
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

  def create_record #:nodoc:
    run_callbacks(:create) {}
  end
  alias_method :create, :create_record # for rails3

  def update_record(*) #:nodoc:
    run_callbacks(:update) {}
  end
  alias_method :update, :update_record # for rails3
end
