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

    def to_a
      @klass.find_all(self)
    end

    def find_one(id)
      @klass.find_one(id, self)
    end

    def count
      @klass.count(self)
    end
  end

  def self.columns; @columns ||= []; end
  def self.table_name; @table_name ||= ActiveModel::Naming.plural(self); end
  def self.connection; nil; end
  def self.table_exists?; true; end
  self.abstract_class = true
  class << self
    private
    def relation
      @relation ||= ActiveScaffold::Tableless::Relation.new(self, arel_table)
      super
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

  def self.count(*args)
    if args.size == 1 && args.first.is_a?(Relation)
      find_all(args.first).size
    else
      scoped.count(*args)
    end
  end

  def destroy
    raise 'destroy must be implemented in a Tableless model'
  end
end
