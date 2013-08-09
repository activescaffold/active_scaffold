class Company < ActiveRecord::Base
  def initialize(with_or_without = nil)
    @with_companies = with_or_without == :with_companies
    @with_company = with_or_without == :with_company
    @with_main_company = with_or_without == :with_main_company
    @attributes = {}
    @attributes_cache = {}
  end
  
  def self.columns_hash
    {
      'name' => ActiveRecord::ConnectionAdapters::Column.new('name', nil, 'varchar(255)'),
      'date' => ActiveRecord::ConnectionAdapters::Column.new('date', nil, 'date'),
      'datetime' => ActiveRecord::ConnectionAdapters::Column.new('datetime', nil, 'datetime'),
      'logo_file_name' => ActiveRecord::ConnectionAdapters::Column.new('logo_file_name', nil, 'varchar(255)'),
      'logo_content_type' => ActiveRecord::ConnectionAdapters::Column.new('logo_content_type', nil, 'varchar(255)'),
      'logo_file_size' => ActiveRecord::ConnectionAdapters::Column.new('logo_file_size', nil, 'int(11)'),
      'logo_updated_at' => ActiveRecord::ConnectionAdapters::Column.new('logo_updated_at', nil, 'datetime'),
    }
  end

  def self.columns
    self.columns_hash.values
  end
  
  def self.class_name
    self.name
  end
  
  def self.table_name
    'companies'
  end
  
  def self.attachment_definitions
    {:logo => {}}
  end
  
  # not the real signature of the method, but forgive me
  def self.before_destroy(s=nil)
    @@before = s
  end

  if method(:create_reflection).arity == 4
    def self.create_reflection(macro, name, scope, options, active_record)
      super(macro, name, options, active_record)
    end
  end
  
  def self.has_many(association_id, options = {})
    reflection = create_reflection(:has_many, association_id, nil, options, self)
  end
  def self.has_one(association_id, options = {})
    reflection = create_reflection(:has_one, association_id, nil, options, self)
  end
  def self.belongs_to(association_id, options = {})
    reflection = create_reflection(:belongs_to, association_id, nil, options, self)
  end
  has_many :companies
  has_one :company
  belongs_to :main_company, :class_name => 'Company'
  
  def companies
    if @with_companies
      [nil]
    else
      []
    end
  end
  
  def company
    @with_company
  end
  
  def main_company
    @with_main_company
  end
  
  def name
  end

  def date
    Date.today
  end

  def datetime
    Time.now
  end
end
