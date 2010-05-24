require 'rubygems'
require 'active_record'
require 'active_record/reflection'
require File.join(File.dirname(__FILE__), '../../lib/bridges/dependent_protect/lib/dependent_protect_bridge')

# Mocking everything necesary to test the plugin.
class Company
  def initialize(with_or_without = nil)
    @with_companies = with_or_without == :with_companies
    @with_company = with_or_without == :with_company
    @with_main_company = with_or_without == :with_main_company
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
  
  include ActiveRecord::Reflection
  include DependentProtectSecurity
  
  def self.has_many(association_id, options = {})
    reflection = create_reflection(:has_many, association_id, options, self)
  end
  def self.has_one(association_id, options = {})
    reflection = create_reflection(:has_one, association_id, options, self)
  end
  def self.belongs_to(association_id, options = {})
    reflection = create_reflection(:belongs_to, association_id, options, self)
  end
  has_many :companies, :dependent => :protect
  has_one :company, :dependent => :protect
  belongs_to :main_company, :dependent => :protect, :class_name => 'Company'
  
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
end
