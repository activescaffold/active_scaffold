# frozen_string_literal: true

require 'test_helper'

class TabbedAssociationTest < ActiveSupport::TestCase
  setup do
    @controller = ProjectsController.new
    @tasks = ProjectsController.active_scaffold_config.columns[:tasks]
  end

  test 'non-polymorphic tabs use their declared association class' do
    category = Category.create!(name: 'Category')
    task = Task.new

    @controller.send(:assign_tabbed_by, task, @tasks, 'category', category.id, nil)

    assert_equal category, task.category
  end

  test 'supplied value types cannot replace a non-polymorphic association class' do
    category = Category.create!(name: 'Category')
    task = Task.new
    Person.expects(:find).never

    @controller.send(:assign_tabbed_by, task, @tasks, 'category', category.id, 'Person')

    assert_equal category, task.category
  end

  test 'non-polymorphic tabs ignore arbitrary supplied constants' do
    category = Category.create!(name: 'Category')
    task = Task.new

    @controller.send(:assign_tabbed_by, task, @tasks, 'category', category.id, 'Kernel')

    assert_equal category, task.category
  end

  test 'polymorphic tabs resolve the supplied record type' do
    person = Person.create!(first_name: 'Person')
    contact = Contact.new
    contacts = PeopleController.active_scaffold_config.columns[:contacts]

    @controller.send(:assign_tabbed_by, contact, contacts, 'contactable', person.id, 'Person')

    assert_equal person, contact.contactable
  end

  test 'polymorphic tabs reject missing and blank record types' do
    contacts = PeopleController.active_scaffold_config.columns[:contacts]

    [nil, '', ' '].each do |value_type|
      assert_raises(ActionController::BadRequest) do
        @controller.send(:assign_tabbed_by, Contact.new, contacts, 'contactable', '1', value_type)
      end
    end
  end

  test 'scalar tabs retain direct value assignment' do
    task = Task.new

    @controller.send(:assign_tabbed_by, task, @tasks, 'priority', 'high', nil)

    assert_equal 'high', task.priority
  end
end
