require 'test_helper'

class PermissionModel < ActiveRecord::Base
  include ActiveScaffold::ActiveRecordPermissions::ModelUserAccess::Model
  def self.columns; @columns ||= [ColumnMock.new('id', '', 'int(11)')] + %w(a1 a2 a3 b1 b2 b3 c1 c2 c3).map { |c| ColumnMock.new(c, '', 'varchar(255)') }; end

  def authorized_for_read?; true; end

  def authorized_for_update?; false; end
  # def authorized_for_create?; end

  def a1_authorized?; true; end

  def a2_authorized?; false; end
  # def a3_authorized?; end

  def b1_authorized?; true; end

  def b2_authorized?; false; end
  # def b3_authorized?; end

  def c1_authorized?; true; end

  def c2_authorized?; false; end
  # def c3_authorized?; end

  def a3_authorized_for_create?; true; end

  def b3_authorized_for_create?; false; end
  # def c3_authorized_for_create?; end
  def a2_authorized_for_create?; true; end

  def b2_authorized_for_create?; false; end
  # def c2_authorized_for_create?; end
  def a1_authorized_for_create?; true; end

  def b1_authorized_for_create?; false; end
  # def c1_authorized_for_create?; end

  def a3_authorized_for_read?; true; end

  def b3_authorized_for_read?; false; end
  # def c3_authorized_for_read?; end
  def a2_authorized_for_read?; true; end

  def b2_authorized_for_read?; false; end
  # def c2_authorized_for_read?; end
  def a1_authorized_for_read?; true; end

  def b1_authorized_for_read?; false; end
  # def c1_authorized_for_read?; end

  def a3_authorized_for_update?; true; end

  def b3_authorized_for_update?; false; end
  # def c3_authorized_for_update?; end
  def a2_authorized_for_update?; true; end

  def b2_authorized_for_update?; false; end
  # def c2_authorized_for_update?; end
  def a1_authorized_for_update?; true; end

  def b1_authorized_for_update?; false; end
  # def c1_authorized_for_update?; end
end

class ActiveRecordPermissionsTest < MiniTest::Test
  def setup
    @model = PermissionModel.new
  end

  # Combinations Legend:
  #   columns are: crud_type method, column method, crud_type/column method
  #   symbols are: is (a)bsent, returns (f)alse, returns (t)rue, or n/a (_)
  def test_method_combinations_with_default_true
    old_permission = nil
    ActiveScaffold.set_defaults do |config|
      old_permission = config.security.default_permission
      config.security.default_permission = true
    end

    pass(@model.authorized_for?(:column => :a3), '_a_')
    miss(@model.authorized_for?(:column => :a2), '_f_')
    pass(@model.authorized_for?(:column => :a1), '_t_')

    pass(@model.authorized_for?(:crud_type => :create), 'a__')
    miss(@model.authorized_for?(:crud_type => :update), 'f__')
    pass(@model.authorized_for?(:crud_type => :read), 't__')

    pass(@model.authorized_for?(:crud_type => :create, :column => :c3), 'aaa')
    miss(@model.authorized_for?(:crud_type => :create, :column => :b3), 'aaf')
    pass(@model.authorized_for?(:crud_type => :create, :column => :a3), 'aat')
    miss(@model.authorized_for?(:crud_type => :create, :column => :c2), 'afa')
    miss(@model.authorized_for?(:crud_type => :create, :column => :b2), 'aff')
    pass(@model.authorized_for?(:crud_type => :create, :column => :a2), 'aft')
    pass(@model.authorized_for?(:crud_type => :create, :column => :c1), 'ata')
    miss(@model.authorized_for?(:crud_type => :create, :column => :b1), 'atf')
    pass(@model.authorized_for?(:crud_type => :create, :column => :a1), 'att')

    miss(@model.authorized_for?(:crud_type => :update, :column => :c3), 'faa')
    miss(@model.authorized_for?(:crud_type => :update, :column => :b3), 'faf')
    pass(@model.authorized_for?(:crud_type => :update, :column => :a3), 'fat')
    miss(@model.authorized_for?(:crud_type => :update, :column => :c2), 'ffa')
    miss(@model.authorized_for?(:crud_type => :update, :column => :b2), 'fff')
    pass(@model.authorized_for?(:crud_type => :update, :column => :a2), 'fft')
    miss(@model.authorized_for?(:crud_type => :update, :column => :c1), 'fta')
    miss(@model.authorized_for?(:crud_type => :update, :column => :b1), 'ftf')
    pass(@model.authorized_for?(:crud_type => :update, :column => :a1), 'ftt')

    pass(@model.authorized_for?(:crud_type => :read, :column => :c3), 'taa')
    miss(@model.authorized_for?(:crud_type => :read, :column => :b3), 'taf')
    pass(@model.authorized_for?(:crud_type => :read, :column => :a3), 'tat')
    miss(@model.authorized_for?(:crud_type => :read, :column => :c2), 'tfa')
    miss(@model.authorized_for?(:crud_type => :read, :column => :b2), 'tff')
    pass(@model.authorized_for?(:crud_type => :read, :column => :a2), 'tft')
    pass(@model.authorized_for?(:crud_type => :read, :column => :c1), 'tta')
    miss(@model.authorized_for?(:crud_type => :read, :column => :b1), 'ttf')
    pass(@model.authorized_for?(:crud_type => :read, :column => :a1), 'ttt')

    ActiveScaffold.set_defaults do |config|
      config.security.default_permission = old_permission
    end
  end

  def test_method_combinations_with_default_false
    old_permission = nil
    ActiveScaffold.set_defaults do |config|
      old_permission = config.security.default_permission
      config.security.default_permission = false
    end

    miss(@model.authorized_for?(:column => :a3), '_a_')
    miss(@model.authorized_for?(:column => :a2), '_f_')
    pass(@model.authorized_for?(:column => :a1), '_t_')

    miss(@model.authorized_for?(:crud_type => :create), 'a__')
    miss(@model.authorized_for?(:crud_type => :update), 'f__')
    pass(@model.authorized_for?(:crud_type => :read), 't__')

    miss(@model.authorized_for?(:crud_type => :create, :column => :c3), 'aaa')
    miss(@model.authorized_for?(:crud_type => :create, :column => :b3), 'aaf')
    pass(@model.authorized_for?(:crud_type => :create, :column => :a3), 'aat')
    miss(@model.authorized_for?(:crud_type => :create, :column => :c2), 'afa')
    miss(@model.authorized_for?(:crud_type => :create, :column => :b2), 'aff')
    pass(@model.authorized_for?(:crud_type => :create, :column => :a2), 'aft')
    pass(@model.authorized_for?(:crud_type => :create, :column => :c1), 'ata')
    miss(@model.authorized_for?(:crud_type => :create, :column => :b1), 'atf')
    pass(@model.authorized_for?(:crud_type => :create, :column => :a1), 'att')

    miss(@model.authorized_for?(:crud_type => :update, :column => :c3), 'faa')
    miss(@model.authorized_for?(:crud_type => :update, :column => :b3), 'faf')
    pass(@model.authorized_for?(:crud_type => :update, :column => :a3), 'fat')
    miss(@model.authorized_for?(:crud_type => :update, :column => :c2), 'ffa')
    miss(@model.authorized_for?(:crud_type => :update, :column => :b2), 'fff')
    pass(@model.authorized_for?(:crud_type => :update, :column => :a2), 'fft')
    miss(@model.authorized_for?(:crud_type => :update, :column => :c1), 'fta')
    miss(@model.authorized_for?(:crud_type => :update, :column => :b1), 'ftf')
    pass(@model.authorized_for?(:crud_type => :update, :column => :a1), 'ftt')

    pass(@model.authorized_for?(:crud_type => :read, :column => :c3), 'taa')
    miss(@model.authorized_for?(:crud_type => :read, :column => :b3), 'taf')
    pass(@model.authorized_for?(:crud_type => :read, :column => :a3), 'tat')
    miss(@model.authorized_for?(:crud_type => :read, :column => :c2), 'tfa')
    miss(@model.authorized_for?(:crud_type => :read, :column => :b2), 'tff')
    pass(@model.authorized_for?(:crud_type => :read, :column => :a2), 'tft')
    pass(@model.authorized_for?(:crud_type => :read, :column => :c1), 'tta')
    miss(@model.authorized_for?(:crud_type => :read, :column => :b1), 'ttf')
    pass(@model.authorized_for?(:crud_type => :read, :column => :a1), 'ttt')

    ActiveScaffold.set_defaults do |config|
      config.security.default_permission = old_permission
    end
  end

  private

  def pass(value, message = nil)
    assert value, "#{message} should pass"
  end

  def miss(value, message = nil)
    refute value, "#{message} should fail"
  end
end
