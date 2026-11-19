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
end
