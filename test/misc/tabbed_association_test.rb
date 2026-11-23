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

  test 'existing association values are staged without saving the record' do
    previous_category = Category.create!(name: 'Previous')
    category = Category.create!(name: 'New')
    task = Task.create!(name: 'Task', category: previous_category)

    @controller.send(:assign_tabbed_by, task, @tasks, 'category', category.id, nil)

    assert_equal category, task.category
    assert_equal previous_category.id, Task.find(task.id).category_id
  end

  test 'unchanged numeric grouping values do not require update permission' do
    project = Project.create!(name: 'Project')
    task = Task.create!(name: 'Task', project: project)
    task.expects(:authorized_for?).never

    @controller.send(:assign_tabbed_by, task, @tasks, 'project_id', project.id.to_s, nil)

    assert_equal project.id, task.project_id
  end

  test 'existing has-one grouping values are staged without saving either side' do
    person = Person.create!(first_name: 'Person')
    previous_car = Car.create!(model: 'Previous', person: person)
    car = Car.create!(model: 'New')
    people = RolesController.active_scaffold_config.columns[:people]

    @controller.send(:assign_tabbed_by, person, people, 'car', car.id, nil)

    assert_equal car, person.car
    assert_equal previous_car.id, Person.find(person.id).car.id
    assert_nil car.reload.person_id
  end
end
