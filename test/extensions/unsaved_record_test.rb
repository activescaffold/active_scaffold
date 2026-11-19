# frozen_string_literal: true

require 'test_helper'

class UnsavedRecordTest < ActiveSupport::TestCase
  test 'restores errors removed while validating and reports existing errors' do
    person = Person.new
    person.errors.add(:first_name, 'was already invalid')

    result = person.keeping_errors do
      person.errors.clear
      true
    end

    assert_not result
    assert person.errors.added?(:first_name, 'was already invalid')
  end

  test 'returns the block result when there were no existing errors' do
    person = Person.new

    assert(person.keeping_errors { true })
    assert_not(person.keeping_errors { false })
  end

  test 'clears the unsaved flag after saving' do
    person = Person.new(first_name: 'Alice')
    person.unsaved = true

    assert person.save
    assert_not person.unsaved?
  end

  test 'reports errors in unsaved associated records' do
    person = Person.new(first_name: 'Alice')
    building = person.buildings.build(name: 'Home')
    building.unsaved = true
    building.errors.add(:name, 'is invalid')

    assert_not person.no_errors_in_associated?
  end

  test 'association traversal honors nofollow and follow lists' do
    associations = Person.reflect_on_all_associations
    person = Person.new

    person.define_singleton_method(:scaffold_update_nofollow) { [:buildings] }
    assert_not_includes person.send(:associations_for_update).map(&:name), :buildings

    person.singleton_class.remove_method(:scaffold_update_nofollow)
    person.define_singleton_method(:scaffold_update_follow) { [:contacts] }
    assert_equal [:contacts], person.send(:associations_for_update).map(&:name)
    assert_includes associations.map(&:name), :contacts
  end
end
