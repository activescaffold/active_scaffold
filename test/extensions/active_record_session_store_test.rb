# frozen_string_literal: true

require 'test_helper'
require 'active_scaffold/extensions/active_record_session_store'

class ActiveRecordSessionStoreTest < ActiveSupport::TestCase
  Extension = ActiveScaffold::Extensions::ActiveRecordSessionStore

  class Controller
    prepend Extension::Core

    attr_accessor :session

    def active_scaffold_session_storage_key(id = nil)
      "as:#{id || 'models'}"
    end
  end

  def setup
    @controller = Controller.new
  end

  def test_storage_is_detached_from_loaded_session_data
    loaded_data = {'as:models' => {'list' => {'sort' => 'name'}}}
    @controller.session = loaded_data.dup

    storage = @controller.active_scaffold_session_storage
    storage['list']['sort'] = 'email'

    assert_equal 'name', loaded_data['as:models']['list']['sort']
    assert_equal 'email', @controller.session['as:models']['list']['sort']
    assert_not_equal loaded_data, @controller.session
  end

  def test_unchanged_copy_remains_value_equal_to_loaded_session_data
    loaded_data = {'as:models' => {'list' => {'sort' => 'name'}}}
    @controller.session = loaded_data.dup

    @controller.active_scaffold_session_storage

    assert_equal loaded_data, @controller.session
    assert_not_same loaded_data['as:models'], @controller.session['as:models']
  end

  def test_storage_is_memoized_per_session_key
    @controller.session = {'as:models' => {'list' => {}}}

    storage = @controller.active_scaffold_session_storage

    assert_same storage, @controller.active_scaffold_session_storage
    assert_same storage, @controller.session['as:models']
  end

  def test_storage_is_replaced_after_session_is_reset
    @controller.session = {'as:models' => {'list' => {'sort' => 'name'}}}
    old_storage = @controller.active_scaffold_session_storage
    @controller.session.clear

    new_storage = @controller.active_scaffold_session_storage

    assert_not_same old_storage, new_storage
    assert_empty new_storage
    assert_same new_storage, @controller.session['as:models']
  end

  def test_affected_when_version_and_configured_store_match
    active_record_store = Class.new
    application = application_using(active_record_store)
    stub_session_store(active_record_store, '2.3.0')

    assert Extension.affected?(application)
  end

  def test_affected_for_active_record_store_subclass
    active_record_store = Class.new
    application = application_using(Class.new(active_record_store))
    stub_session_store(active_record_store, '2.3.0')

    assert Extension.affected?(application)
  end

  def test_not_affected_with_another_version_or_store
    active_record_store = Class.new
    stub_session_store(active_record_store, '2.3.1')

    assert_not Extension.affected?(application_using(active_record_store))

    stub_session_store(active_record_store, '2.3.0')

    assert_not Extension.affected?(application_using(Class.new))
  end

  private

  def application_using(store)
    config = Struct.new(:session_store).new(store)
    Struct.new(:config).new(config)
  end

  def stub_session_store(store, version)
    Extension.stubs(:active_record_store).returns(store)
    Extension.stubs(:session_store_version).returns(version)
  end
end
