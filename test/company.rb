class Company < ActiveRecord::Base
  def initialize(with_or_without = nil)
    @companies = with_or_without == :with_companies
    @company = with_or_without == :with_company
    @main_company = with_or_without == :with_main_company
    @attributes = {}
    @attributes_cache = {}
    @raw_attributes = {}
  end

  def self.columns_hash
    {
      'name' => ColumnMock.new('name', nil, 'varchar(255)'),
      'date' => ColumnMock.new('date', nil, 'date'),
      'datetime' => ColumnMock.new('datetime', nil, 'datetime'),
      'logo_file_name' => ColumnMock.new('logo_file_name', nil, 'varchar(255)'),
      'logo_content_type' => ColumnMock.new('logo_content_type', nil, 'varchar(255)'),
      'logo_file_size' => ColumnMock.new('logo_file_size', nil, 'int(11)'),
      'logo_updated_at' => ColumnMock.new('logo_updated_at', nil, 'datetime')
    }
  end

  def self.columns
    columns_hash.values
  end

  def self.class_name
    name
  end

  def self.table_name
    'companies'
  end

  def self.attachment_definitions
    {:logo => {}}
  end

  # not the real signature of the method, but forgive me
  def self.before_destroy(s = nil)
    @@before = s
  end

  if respond_to?(:create_reflection)
    if method(:create_reflection).arity == 4
      def self.create_reflection(macro, name, scope, options, active_record)
        super(macro, name, options, active_record)
      end
    end
  else
    def self.create_reflection(*args)
      ActiveRecord::Reflection.create *args
    end
  end

  def self.has_many(association_id, options = {})
    create_reflection(:has_many, association_id, nil, options, self)
  end
  def self.has_one(association_id, options = {})
    create_reflection(:has_one, association_id, nil, options, self)
  end
  def self.belongs_to(association_id, options = {})
    create_reflection(:belongs_to, association_id, nil, options, self)
  end
  has_many :companies
  has_one :company
  belongs_to :main_company, :class_name => 'Company'

  def companies
    if @companies
      [nil]
    else
      []
    end
  end

  attr_reader :company
  attr_reader :main_company

  def name; end

  def name_before_type_cast
    name.to_s
  end

  def name_came_from_user?; end

  def date
    Date.today
  end

  def datetime
    Time.now
  end
end
