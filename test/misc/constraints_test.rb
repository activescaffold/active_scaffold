require 'test_helper'

module ModelStubs
  class ModelStub < ActiveRecord::Base
    self.abstract_class = true
    def self.columns; @columns ||= [ColumnMock.new('foo', '', 'string')] end

    def self.columns_hash; @hash ||= Hash[@columns.map { |c| [c.name, c] }] end

    if respond_to? :type_for_attribute
      def self.type_for_attribute(column_name)
        defined?(ActiveModel::Type) ? ActiveModel::Type::String.new : super
      end
    end

    def self.table_name
      @table_name || to_s.split('::').last.underscore.pluralize
    end
    self.store_full_sti_class = false
  end

  ##
  ## Standard associations
  ##

  class Address < ModelStub
    belongs_to :addressable, :polymorphic => true
  end

  class User < ModelStub
    has_and_belongs_to_many :roles
    has_one :subscription
    has_one :address, :as => :addressable
  end

  class Service < ModelStub
    has_many :subscriptions
    has_many :users, :through => :subscriptions
  end

  class Subscription < ModelStub
    belongs_to :service
    belongs_to :user
  end

  class Role < ModelStub
    has_and_belongs_to_many :users
  end

  ##
  ## These versions of the associations require extra configuration to work properly
  ##

  class OtherAddress < ModelStub
    self.table_name = 'addresses'
    belongs_to :other_addressable, :polymorphic => true
  end

  class OtherUser < ModelStub
    self.table_name = 'users'
    has_and_belongs_to_many :other_roles, :class_name => 'ModelStubs::OtherRole', :foreign_key => 'user_id', :association_foreign_key => 'role_id', :join_table => 'roles_users'
    has_one :other_subscription, :class_name => 'ModelStubs::OtherSubscription', :foreign_key => 'user_id'
    has_one :other_address, :as => :other_addressable, :class_name => 'ModelStubs::OtherAddress', :foreign_key => 'addressable_id'
  end

  class OtherService < ModelStub
    self.table_name = 'services'
    has_many :other_subscriptions, :class_name => 'ModelStubs::OtherSubscription', :foreign_key => 'service_id'
    has_many :other_users, :through => :other_subscriptions # :class_name and :foreign_key are ignored for :through
  end

  class OtherSubscription < ModelStub
    self.table_name = 'subscriptions'
    belongs_to :other_service, :class_name => 'ModelStubs::OtherService', :foreign_key => 'service_id'
    belongs_to :other_user, :class_name => 'ModelStubs::OtherUser', :foreign_key => 'user_id'
  end

  class OtherRole < ModelStub
    self.table_name = 'roles'
    has_and_belongs_to_many :other_users, :class_name => 'ModelStubs::OtherUser', :foreign_key => 'role_id', :association_foreign_key => 'user_id', :join_table => 'roles_users'
  end

  class PrimaryKeyUser < ModelStub
    has_many :locations, :class_name => 'PrimaryKeyLocation', :foreign_key => :username, :primary_key => :name
  end

  class PrimaryKeyLocation < ModelStub
    belongs_to :user, :class_name => 'PrimaryKeyUser', :foreign_key => :username, :primary_key => :name
  end
end

class ConstraintsTestObject
  # stub out what the mixin expects to find ...
  def self.before_action(*); end

  def self.helper_method(*); end
  attr_accessor :active_scaffold_preload
  attr_accessor :active_scaffold_references
  attr_accessor :active_scaffold_habtm_joins
  attr_accessor :active_scaffold_config
  attr_accessor :params
  def merge_conditions(old, new)
    [old, new].compact.flatten
  end

  # mixin the constraint code
  include ActiveScaffold::Constraints

  # make the constraints read-write, instead of coming from the session
  attr_accessor :active_scaffold_constraints

  def initialize
    @active_scaffold_preload = []
    @active_scaffold_references = []
    @active_scaffold_habtm_joins = []
    @params = {}
  end

  def params_hash?(value)
    value.is_a? Hash
  end
end

class ConstraintsTest < MiniTest::Test
  def setup
    @test_object = ConstraintsTestObject.new
  end

  def test_constraint_conditions_for_default_associations
    @test_object.active_scaffold_config = config_for('user')
    # has_one (vs belongs_to)
    assert_constraint_condition({:subscription => 5}, [{'subscriptions' => {'id' => 5}}], 'find the user with subscription #5')
    # habtm (vs habtm)
    assert_constraint_condition({:roles => 4}, [{'roles' => {'id' => 4}}], 'find all users with role #4')
    # has_one (vs polymorphic)
    assert_constraint_condition({:address => 11}, [{'addresses' => {'id' => 11}}], 'find the user with address #11')
    # reverse of a has_many :through
    assert_constraint_condition({:subscription => {:service => 5}}, [{'services' => {'id' => 5}}], 'find all users subscribed to service #5')
    assert(@test_object.active_scaffold_references.include?(:subscription => :service), 'multi-level association include')

    @test_object.active_scaffold_config = config_for('subscription')
    # belongs_to (vs has_one)
    assert_constraint_condition({:user => 2}, [{'subscriptions' => {'user_id' => 2}}], 'find the subscription for user #2')
    # belongs_to (vs has_many)
    assert_constraint_condition({:service => 1}, [{'subscriptions' => {'service_id' => 1}}], 'find all subscriptions for service #1')

    @test_object.active_scaffold_config = config_for('service')
    # has_many (vs belongs_to)
    assert_constraint_condition({:subscriptions => 10}, [{'subscriptions' => {'id' => 10}}], 'find the service with subscription #10')
    # has_many :through (through has_many)
    assert_constraint_condition({:users => 7}, [{'users' => {'id' => 7}}], 'find the service with user #7')

    @test_object.active_scaffold_config = config_for('address')
    # belongs_to :polymorphic => true
    assert_constraint_condition({:addressable => ['ModelStubs::User', 14]}, [{'addresses' => {'addressable_id' => 14, 'addressable_type' => 'ModelStubs::User'}}], 'find all addresses for user #14')
  end

  def test_constraint_conditions_for_configured_associations
    @test_object.active_scaffold_config = config_for('other_user')
    # has_one (vs belongs_to)
    assert_constraint_condition({:other_subscription => 5}, [{'subscriptions' => {'id' => 5}}], 'find the user with subscription #5')
    # habtm (vs habtm)
    assert_constraint_condition({:other_roles => 4}, [{'roles' => {'id' => 4}}], 'find all users with role #4')
    # has_one (vs polymorphic)
    assert_constraint_condition({:other_address => 11}, [{'addresses' => {'id' => 11}}], 'find the user with address #11')
    # reverse of a has_many :through
    assert_constraint_condition({:other_subscription => {:other_service => 5}}, [{'services' => {'id' => 5}}], 'find all users subscribed to service #5')

    @test_object.active_scaffold_config = config_for('other_subscription')
    # belongs_to (vs has_one)
    assert_constraint_condition({:other_user => 2}, [{'subscriptions' => {'user_id' => 2}}], 'find the subscription for user #2')
    # belongs_to (vs has_many)
    assert_constraint_condition({:other_service => 1}, [{'subscriptions' => {'service_id' => 1}}], 'find all subscriptions for service #1')

    @test_object.active_scaffold_config = config_for('other_service')
    # has_many (vs belongs_to)
    assert_constraint_condition({:other_subscriptions => 10}, [{'subscriptions' => {'id' => 10}}], 'find the service with subscription #10')
    # has_many :through (through has_many)
    assert_constraint_condition({:other_users => 7}, [{'users' => {'id' => 7}}], 'find the service with user #7')

    @test_object.active_scaffold_config = config_for('other_address')
    # belongs_to :polymorphic => true
    assert_constraint_condition({:other_addressable => ['ModelStubs::OtherUser', 14]}, [{'addresses' => {'other_addressable_id' => 14, 'other_addressable_type' => 'ModelStubs::OtherUser'}}], 'find all addresses for user #14')
  end

  def test_constraint_conditions_for_normal_attributes
    @test_object.active_scaffold_config = config_for('user')
    assert_constraint_condition({'foo' => 'bar'}, [['"users"."foo" = ?', 'bar']], 'normal column-based constraint')
  end

  def test_constraint_conditions_for_associations_with_primary_key_option
    @test_object.active_scaffold_config = config_for('primary_key_location')
    # user = ModelStubs::PrimaryKeyUser.new(:id => 1, :name => 'User Name')
    ModelStubs::PrimaryKeyUser.expects(:find).with(1).returns(stub(:id => 1, :name => 'User Name'))
    assert_constraint_condition({'user' => 1}, [{'primary_key_locations' => {'username' => 'User Name'}}], 'association with primary-key constraint')
  end

  protected

  def assert_constraint_condition(constraint, condition, message = nil)
    @test_object.active_scaffold_constraints = constraint
    assert_equal condition, @test_object.send(:conditions_from_constraints), message
  end

  def config_for(klass, namespace = nil)
    super(klass, 'model_stubs/')
  end
end
