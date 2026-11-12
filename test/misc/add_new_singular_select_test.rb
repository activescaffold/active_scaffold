# frozen_string_literal: true

require 'test_helper'

class AddNewSingularSelectTest < ActionDispatch::IntegrationTest
  setup do
    RequestStore.clear!
    [Task, Category].each(&:delete_all)
  end

  teardown do
    [Task, Category].each(&:delete_all)
    RequestStore.clear!
  end

  test 'failed validation redisplays the new associated record with its values and errors' do
    post '/tasks', params: {
      record: {
        name: 'Test task',
        category: {name: 'x'}
      }
    }

    assert_response :success
    assert_select '.category-sub-form.optional:not([style])' do
      assert_select 'input[name=?][value=?]', 'record[category][name]', 'x'
      assert_select '.association-record-errors', text: /Name is too short/
    end
    assert_select 'a.show-new-subform', text: I18n.t('active_scaffold.add_existing')
    assert_equal 0, Task.count
    assert_equal 0, Category.count
  end
end
