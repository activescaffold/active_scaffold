class ActiveScaffold::Tableless < ActiveRecord::Base
  class Relation < ActiveRecord::Relation
    attr_reader :conditions
    def initialize(klass, table)
      super
      @conditions ||= []
    end

    def initialize_copy(other)
      @conditions = @conditions.dup
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

  def self.columns; @columns ||= []; end
  def self.table_name; @table_name ||= ActiveModel::Naming.plural(self); end
  def self.table_exists?; true; end
  self.abstract_class = true
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
    if operation == 'count' && column_name == :all && !distinct
      find_all(relation).size
    else
      raise "self.execute_simple_calculation must be implemented in a Tableless model to support #{operation} #{column_name} #{' distinct' if distinct} columns"
    end
  end

  def destroy
    raise 'destroy must be implemented in a Tableless model'
  end

  def create #:nodoc:
    run_callbacks(:create) {}
  end

  def update(*) #:nodoc:
    run_callbacks(:update) {}
  end
end
