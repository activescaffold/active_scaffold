# frozen_string_literal: true

require_relative 'test_helper'

class InstalledRecordSelectBridgeTest < InstalledBridgeTestCase
  include ActiveScaffold::Bridges::RecordSelect::Helpers

  def test_record_select_bridge_renders_collections_and_restores_search_values
    bridge = assert_installed_bridge(:record_select)
    expected_assets = ['record_select']
    expected_assets << 'active_scaffold/record_select_bridge' if RecordSelect.callback_registry?
    config = ActiveScaffold::Config::Core.new(:project)
    column = config.columns[:tasks]
    project = Project.new
    controller = stub(controller_path: 'tasks')
    stubs(:active_scaffold_controller_for).with(Task).returns(controller)
    stubs(:record_multi_select_field).returns('<record-select multiple>')

    assert_equal expected_assets, bridge.javascripts
    assert_equal RecordSelect.callback_registry?, bridge.callback_registry?

    html = active_scaffold_input_record_select(
      column,
      {name: 'record[tasks]', id: 'record_tasks', class: 'task-input', object: project}
    )
    assert_equal '<record-select multiple>', html

    first = Task.create!(name: 'First')
    second = Task.create!(name: 'Second')
    assert_equal [first, second], field_search_record_select_value(
      column, [first.id.to_s, '', second.id.to_s], ui_options: {multiple: true}
    )

    simple_column = ActiveScaffold::Config::Core.new(:company).columns[:name]
    error = assert_raises ArgumentError do
      active_scaffold_record_select(Company.new, simple_column, {name: 'record[name]'}, nil, false)
    end
    assert_includes error.message, 'record_select can only work against associations'
  end

  def test_record_select_bridge_renders_autocomplete_for_plain_columns
    assert_installed_bridge(:record_select)
    config = ActiveScaffold::Config::Core.new(:company)
    column = config.columns[:name]
    record = Company.new
    stubs(:active_scaffold_controller_for).with(Company).returns(stub(controller_path: 'companies'))
    expects(:record_select_autocomplete)
      .with(
        'record[name]', record,
        {
          controller: 'companies', name: 'record[name]', id: 'record_name', class: 'name-input text-input',
          autocomplete: 'off'
        }
      )
      .returns('<record-select autocomplete>')

    html = active_scaffold_input_record_select(
      column,
      {name: 'record[name]', id: 'record_name', class: 'name-input', object: record}
    )

    assert_equal '<record-select autocomplete>', html
  end

  def test_record_select_bridge_renders_singular_associations_with_add_new
    assert_installed_bridge(:record_select)
    column = ActiveScaffold::Config::Core.new(:task).columns[:project]
    project = Project.new(name: 'Existing')
    task = Task.new(project: project)
    options = {name: 'record[project]', id: 'record_project', class: 'project-input', object: task}
    ui_options = {controller: 'available_projects', add_new: {mode: :popup}}
    stubs(:active_scaffold_controller_for).with(Project).returns(stub(controller_path: 'projects'))
    expects(:record_select_field)
      .with(
        'record[project]', project,
        {
          name: 'record[project]', id: 'record_project', class: 'project-input text-input', autocomplete: 'off',
          controller: 'available_projects'
        }
      )
      .returns('<input class="record-select">'.html_safe)
    expects(:active_scaffold_add_new)
      .with(
        column, task,
        {
          name: 'record[project]', id: 'record_project', class: 'project-input text-input', autocomplete: 'off'
        },
        ui_options: ui_options
      )
      .returns(content_tag(:a, 'Create project', href: '/projects/new'))

    html = active_scaffold_input_record_select(column, options, ui_options: ui_options)
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css('div.select-field input.record-select')
    assert_equal '/projects/new', fragment.at_css('a')['href']
  end

  def test_record_select_bridge_builds_single_and_multiple_fields
    project = Project.new
    options = {controller: 'projects', required: true}
    stubs(:record_select_field).with('record[project]', project, options).returns(:single)
    stubs(:record_multi_select_field)
      .with('record[tasks]', [], {controller: 'tasks'})
      .returns(:multiple)

    assert_equal :single, record_select_field_for('record[project]', project, Project, false, options)
    assert_equal :multiple, record_select_field_for('record[tasks]', nil, Task, true, options.merge(controller: 'tasks'))
  end

  def test_record_select_bridge_handles_unavailable_association_classes
    record = Project.new
    association = mock
    association.stubs(:klass).with(record).returns(nil)
    column = stub(association: association, options: {})

    html = active_scaffold_record_select(
      record, column, {name: 'record[attachable]', class: 'attachable-input'}, nil, false
    )

    assert_equal '<span class="attachable-input"></span>', html
  end

  def test_record_select_bridge_restores_single_and_blank_search_values
    column = ActiveScaffold::Config::Core.new(:task).columns[:project]
    project = Project.create!(name: 'Found')

    assert_nil field_search_record_select_value(column, '')
    assert_equal project, field_search_record_select_value(column, project.id.to_s)

    error = assert_raises ActiveRecord::RecordNotFound do
      field_search_record_select_value(column, (project.id + 100_000).to_s)
    end
    assert_includes error.message, 'Attempted to restore search values to search fields :project'
    assert_includes error.message, ' in '
  end

  def test_record_select_bridge_renders_restored_search_values
    column = ActiveScaffold::Config::Core.new(:task).columns[:project]
    project = Project.create!(name: 'Search result')
    task = Task.new
    options = {name: 'search[project]', object: task, value: project.id.to_s}
    ui_options = {multiple: false, controller: 'projects'}
    expects(:active_scaffold_record_select)
      .with(task, column, options.except(:value), project, false, ui_options: ui_options)
      .returns('<record-select search>')

    assert_equal '<record-select search>',
                 active_scaffold_search_record_select(column, options, ui_options: ui_options)
  end

  def test_record_select_bridge_configures_column_ui_and_conditions
    association_column = ActiveScaffold::Config::Core.new(:project).columns[:tasks]
    association_column.form_ui = :record_select

    assert_equal :record_select, association_column.form_ui
    assert_equal :record_select, association_column.search_ui

    column = ActiveScaffold::DataStructures::Column.new('first_name', Person)
    assert_equal ['%<search_sql>s IN (?)', %w[1 2]],
                 ClassWithFinder.condition_for_record_select_type(column, ['1', '', '2'])
    assert_equal ['%<search_sql>s = ?', '1'],
                 ClassWithFinder.condition_for_record_select_type(column, '1')
  end

  def test_record_select_bridge_registers_add_existing_callback
    source = File.read(File.join(ASSETS_PATH, 'record_select_bridge.js'))
    bridge = ActiveScaffold::Bridges::RecordSelect
    singleton_class = bridge.singleton_class
    callback_registry = singleton_class.instance_method(:callback_registry?)

    singleton_class.define_method(:callback_registry?) { true }
    assert_equal ['record_select', 'active_scaffold/record_select_bridge'], bridge.javascripts
    singleton_class.define_method(:callback_registry?) { false }
    assert_equal ['record_select'], bridge.javascripts
    assert_includes source, "RecordSelect.registerCallback('active_scaffold.add_existing'"
    assert_includes source, "this.obj.attr('data-edit-associated-url')"
    assert_includes source, "this.obj.attr('data-active-scaffold-id')"
    assert_not_includes source, 'eval('
  ensure
    singleton_class&.define_method(:callback_registry?, callback_registry) if callback_registry
  end

  def test_record_select_add_existing_uses_registry_only_when_supported
    bridge = ActiveScaffold::Bridges::RecordSelect
    singleton_class = bridge.singleton_class
    callback_registry = singleton_class.instance_method(:callback_registry?)
    helper = Object.new.extend(ActiveScaffold::Helpers::AssociationHelpers)
    helper.extend(ActiveScaffold::Helpers::ControllerHelpers)
    helper.define_singleton_method(:url_for) { |_options| '/projects/--ID--' }
    helper.define_singleton_method(:active_scaffold_id) { 'as_projects' }

    singleton_class.define_method(:callback_registry?) { true }
    assert_equal(
      {
        onselect: 'active_scaffold.add_existing',
        html: {data: {edit_associated_url: '/projects/--ID--', active_scaffold_id: 'as_projects'}}
      },
      helper.record_select_params_for_add_existing(nil, {}, nil)
    )

    singleton_class.define_method(:callback_registry?) { false }
    assert_equal(
      {onselect: 'ActiveScaffold.record_select_onselect("/projects/--ID--", "as_projects", id);'},
      helper.record_select_params_for_add_existing(nil, {}, nil)
    )
  ensure
    singleton_class&.define_method(:callback_registry?, callback_registry) if callback_registry
  end

  def test_record_select_add_existing_input_uses_remote_controller
    record_select_config = stub(model: Person)
    controller.singleton_class.define_method(:record_select_config) { record_select_config }
    controller.singleton_class.send(:private, :record_select_config)
    stubs(:record_select_config).returns(record_select_config)
    stubs(:active_scaffold_controller_for).with(Person).returns(stub(controller_path: 'people'))
    captured = nil
    define_singleton_method(:record_select_field) do |name, value, options|
      captured = [name, value, options]
      '<input class="record-select">'.html_safe
    end

    html = active_scaffold_add_existing_input(name: 'associated_id', object: Person.new)

    assert_equal '<input class="record-select">', html
    assert_equal 'associated_id', captured[0]
    assert_nil captured[1]
    assert_equal 'people', captured[2][:controller]
    assert_equal 'off', captured[2][:autocomplete]
    assert_equal 'text-input', captured[2][:class]
    assert_equal 'Person', active_scaffold_add_existing_label
  ensure
    controller.singleton_class.send(:remove_method, :record_select_config)
  end
end
