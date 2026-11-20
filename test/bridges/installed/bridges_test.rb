# frozen_string_literal: true

require_relative 'test_helper'
require 'class_with_finder'

class InstalledAncestryProject < Project
  has_ancestry
end

class InstalledBitfieldsTask < Task
  include Bitfields

  bitfield :project_id, 1 => :featured, 2 => :archived
end

class InstalledCarrierwaveUploader < CarrierWave::Uploader::Base
end

class InstalledCarrierwaveProject < Project
  mount_uploader :document, InstalledCarrierwaveUploader
end

class InstalledDragonflyProject < Project
  extend Dragonfly::Model

  dragonfly_accessor :document
end

class InstalledPaperclipProject < Project
  has_attached_file :document, do_not_validate_attachment_file_type: true
end

class InstalledPaperTrailProject < Project
  has_paper_trail
end

class InstalledBridgesTest < ActionView::TestCase
  ASSETS_PATH = File.expand_path('../../../app/assets/javascripts/active_scaffold', __dir__)

  include InstalledBridgeAssertions
  include ActiveScaffold::Helpers::ViewHelpers
  include ActiveScaffold::Bridges::Ancestry::FormColumnHelpers
  include ActiveScaffold::Bridges::Bitfields::ListColumnHelpers
  include ActiveScaffold::Bridges::Chosen::Helpers
  include ActiveScaffold::Bridges::CountrySelect::FormColumnHelpers
  include ActiveScaffold::Bridges::CountrySelect::ListColumnHelpers
  include ActiveScaffold::Bridges::CountrySelect::SearchColumnHelpers
  include ActiveScaffold::Bridges::RecordSelect::Helpers
  include ActiveScaffold::Bridges::TinyMce::Helpers

  def test_all_optional_gems_are_detected
    InstalledBridgeAssertions::BRIDGE_GEMS.each_key do |bridge_name|
      assert_installed_bridge(bridge_name)
    end
  end

  def test_ancestry_bridge_configures_columns_and_renders_the_tree
    assert_installed_bridge(:ancestry)
    config = ActiveScaffold::Config::Core.new(:installed_ancestry_project)
    root = InstalledAncestryProject.new(name: 'Root')
    child = InstalledAncestryProject.new(name: 'Child', ancestry: '1')
    record = InstalledAncestryProject.new(name: 'Current', ancestry: '1/2')
    root.id = 1
    child.id = 2
    record.id = 3
    InstalledAncestryProject.stubs(:arrange).returns(root => {child => {}})

    assert_equal :ancestry, config.columns[:parent_id].form_ui
    assert_not_includes config.create.columns, :parent_id
    assert_includes config.update.columns, :parent_id

    html = active_scaffold_input_ancestry(
      config.columns[:parent_id],
      {name: 'record[parent_id]', id: 'record_parent_id', object: record}
    )
    assert_includes html, '>Root</option>'
    assert_includes html, '>__Child</option>'
    assert_includes html, 'selected="selected" value="2"'
  end

  def test_bitfields_bridge_builds_checkbox_columns_and_formats_enabled_bits
    assert_installed_bridge(:bitfields)
    config = ActiveScaffold::Config::Core.new(:installed_bitfields_task)
    config._setup_bitfields
    record = InstalledBitfieldsTask.new(project_id: 1)
    @active_scaffold_config = config

    assert_not config.columns[:project_id].number?
    assert_equal :checkbox, config.columns[:featured].form_ui
    assert_equal :checkbox, config.columns[:archived].form_ui
    assert_operator config.columns[:archived].weight, :>, config.columns[:featured].weight
    assert record.featured?
    assert_not record.archived?
    assert_equal 'Featured', format_column_value(record, config.columns[:project_id])
  end

  def test_cancan_bridge_aliases_actions_and_authorizes_records
    assert_installed_bridge(:cancan)

    ability = Class.new { include CanCan::Ability }.new
    ability.as_action_aliases
    ability.can :read, Project
    ability.can :update, Project
    record = Project.new
    ActiveScaffold::Registry.current_ability_proc = proc { ability }

    assert ability.can?(:list, record)
    assert ability.can?(:update_column, record)
    assert record.authorized_for?(crud_type: :update, action: :update_column)
    assert_same ability, Project.current_ability
    assert_raises ActiveScaffold::Bridges::Cancan::ActiveRecord::SecurityMethods::InvalidArgument do
      record.authorized_for?
    end
  ensure
    ActiveScaffold::Registry.current_ability_proc = nil
  end

  def test_carrierwave_bridge_configures_uploads_and_renders_a_thumbnail
    assert_installed_bridge(:carrierwave)
    config = ActiveScaffold::Config::Core.new(:installed_carrierwave_project)
    column = config.columns[:document]
    uploader = stub(file: Object.new, versions: {thumbnail: Object.new})
    uploader.stubs(:url).returns('/documents/original.png')
    uploader.stubs(:url).with(:thumbnail).returns('/documents/thumb.png')
    record = stub(document: uploader)

    assert config.create.multipart?
    assert config.update.multipart?
    assert_equal :carrierwave, column.form_ui
    assert_equal %i[document_cache remove_document], column.params.to_a

    html = active_scaffold_column_carrierwave(record, column)
    assert_includes html, 'src="/documents/thumb.png"'
    assert_includes html, 'href="/documents/original.png"'
    assert_includes html, 'rel="noopener noreferrer"'

    uploader.stubs(:to_s).returns('document.png')
    form = active_scaffold_input_carrierwave(
      column,
      {name: 'record[document]', id: 'record_document', object: record}
    )
    assert_includes form, 'carrierwave_controls'
    assert_includes form, 'name="record[document_cache]"'
    assert_includes form, 'name="record[remove_document]"'
  end

  def test_chosen_bridge_renders_select_and_search_options
    bridge = assert_installed_bridge(:chosen)
    config = ActiveScaffold::Config::Core.new(:company)
    column = config.columns[:name]
    column.options[:options] = [%w[One one], %w[Two two]]
    form_options = {name: 'record[name]', id: 'record_name', class: 'name-input', object: Company.new}

    assert_equal ['chosen-jquery', 'active_scaffold/active_scaffold_chosen'], bridge.javascripts
    assert_includes active_scaffold_input_chosen(column, form_options), 'class="name-input chosen"'

    rendered_options = nil
    define_singleton_method(:active_scaffold_search_select) do |_column, options, **|
      rendered_options = options
      '<chosen-search>'
    end
    search_options = {name: 'search[name]', id: 'search_name', class: 'search-input', object: Company.new}
    assert_equal '<chosen-search>', active_scaffold_search_multi_chosen(column, search_options)
    assert_equal 'search-input chosen', rendered_options[:class]
    assert rendered_options[:multiple]
  end

  def test_chosen_bridge_renders_collection_associations
    assert_installed_bridge(:chosen)
    config = ActiveScaffold::Config::Core.new(:project)
    @active_scaffold_config = config
    column = config.columns[:tasks]
    project = Project.new
    project.tasks.build(name: 'First')
    options = {name: 'record[tasks]', id: 'record_tasks', class: 'task-input', object: project}

    html = active_scaffold_input_chosen(column, options)

    assert_includes html, 'class="task-input chosen"'
    assert_includes html, 'multiple="multiple"'
    assert_includes html, 'name="record[tasks][]"'
  end

  def test_country_select_bridge_uses_the_real_country_data
    assert_installed_bridge(:country_select)
    record = Struct.new(:country).new('US')
    column = Struct.new(:name, :options).new(:country, {})

    assert_method_installed :active_scaffold_column_country
    assert_equal 'United States', active_scaffold_column_country(record, column)
    record.country = 'not-a-country'
    assert_equal 'not-a-country', active_scaffold_column_country(record, column)
    record.country = nil
    assert_nil active_scaffold_column_country(record, column)
    assert CountrySelect::FORMATS.key?(:old)

    record.country = 'US'
    html = active_scaffold_input_country(
      column,
      {name: 'record[country]', id: 'record_country', object: record},
      ui_options: {priority: [:us]}
    )
    assert_includes html, '<select'
    assert_includes html, 'value="US"'
  end

  def test_date_picker_bridge_is_automatically_enabled_by_jquery_ui_rails
    bridge = assert_installed_bridge(:date_picker)
    config = ActiveScaffold::Config::Core.new(:company)

    assert ActiveScaffold.jquery_ui_included?
    assert_equal :date_picker, config.columns[:date].form_ui
    assert_equal :datetime_picker, config.columns[:datetime].form_ui
    assert_equal I18n.locale.to_s, bridge.localization_data[:locale]
  end

  def test_dragonfly_bridge_configures_uploads_and_renders_public_and_private_urls
    assert_installed_bridge(:dragonfly)
    config = ActiveScaffold::Config::Core.new(:installed_dragonfly_project)
    column = config.columns[:document]
    thumb = stub(url: '/documents/thumb.png')
    attachment = stub(image?: true, thumb: thumb, remote_url: '/documents/remote.png', url: '/documents/private.png')
    record = stub(document: attachment)

    assert config.create.multipart?
    assert config.update.multipart?
    assert_equal :dragonfly, column.form_ui
    assert_equal [:remove_document], column.params.to_a

    html = active_scaffold_column_dragonfly(record, column, ui_options: {thumb: '100x100'})
    assert_includes html, 'src="/documents/thumb.png"'
    assert_includes html, 'href="/documents/remote.png"'
    assert_equal '/documents/private.png', dragonfly_url_for_attachment(
      attachment, record, column, ui_options: {private_store: true}
    )

    form = active_scaffold_input_dragonfly(
      column,
      {name: 'record[document]', id: 'record_document', object: record},
      ui_options: {thumb: '100x100'}
    )
    assert_includes form, 'dragonfly_controls'
    assert_includes form, 'name="record[remove_document]"'
  end

  def test_logical_query_parser_bridge_filters_records_for_each_comparator
    assert_installed_bridge(:logical_query_parser)
    column = ActiveScaffold::DataStructures::Column.new('first_name', Person)
    column.search_ui = :select
    column.logical_search = %i[first_name last_name]
    column.search_sql = nil
    ada_lovelace = Person.create!(first_name: 'Ada', last_name: 'Lovelace')
    ada_byron = Person.create!(first_name: 'Ada', last_name: 'Byron')
    grace_hopper = Person.create!(first_name: 'Grace', last_name: 'Hopper')

    all_tokens = ClassWithFinder.condition_for_column(
      column, {opt: 'all_tokens', from: 'Ada Lovelace'}, :full, {}
    )
    any_token = ClassWithFinder.condition_for_column(
      column, {opt: 'any_token', from: 'Byron Grace'}, :full, {}
    )
    logical = ClassWithFinder.condition_for_column(
      column, {opt: 'logical', from: 'Ada AND NOT Byron'}, :full, {}
    )

    assert_equal %w[all_tokens any_token logical], ActiveScaffold::Finder.logical_comparators
    assert_predicate column, :searchable?
    assert_equal [ada_lovelace.id], all_tokens.pluck(:id)
    assert_equal [ada_byron.id, grace_hopper.id].sort, any_token.pluck(:id).sort
    assert_equal [ada_lovelace.id], logical.pluck(:id)

    comparators = active_scaffold_search_range_comparator_options(column).to_h.invert
    assert_equal 'All keywords', comparators['all_tokens']
    assert_equal 'Any keyword', comparators['any_token']
    assert_equal 'Logical', comparators['logical']
  ensure
    Person.delete_all
  end

  def test_paperclip_bridge_configures_uploads_deletes_and_renders_a_thumbnail
    assert_installed_bridge(:paperclip)
    config = ActiveScaffold::Config::Core.new(:installed_paperclip_project)
    column = config.columns[:document]
    paperclip = stub(file?: true, styles: {thumbnail: '40x40'}, original_filename: 'document.png')
    paperclip.stubs(:url).returns('/documents/original.png')
    paperclip.stubs(:url).with(:thumbnail).returns('/documents/thumb.png')
    record = InstalledPaperclipProject.new
    record.stubs(:document).returns(paperclip)

    assert config.create.multipart?
    assert_equal :paperclip, column.form_ui
    assert_equal [:delete_document], column.params.to_a

    html = active_scaffold_column_paperclip(record, column)
    assert_includes html, 'src="/documents/thumb.png"'
    assert_includes html, 'href="/documents/original.png"'

    form = active_scaffold_input_paperclip(
      column,
      {name: 'record[document]', id: 'record_document', object: record}
    )
    assert_includes form, 'paperclip_controls'
    assert_includes form, 'name="record[delete_document]"'

    clean_attachment = stub(dirty?: false)
    record.unstub(:document)
    record.stubs(:document).returns(clean_attachment)
    record.expects(:document=).with(nil)
    record.delete_document = 'true' # rubocop:disable Lint/UselessSetterCall
  end

  def test_paper_trail_bridge_adds_deleted_records_to_versioned_models
    bridge = assert_installed_bridge(:paper_trail)
    bridge.prepare
    config = ActiveScaffold::Config::Core.new(:installed_paper_trail_project)

    assert_equal :get, ActiveScaffold::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING.dig(:collection, :deleted)
    assert_includes config.actions, :deleted_records
    assert_equal :read, config.deleted_records.crud_type
    assert_equal :changes, config.deleted_records.nested_link_label
    assert_equal 'member', config.deleted_records.nested_link_group
  end

  def test_paper_trail_deleted_route
    ActiveScaffold::Bridges::PaperTrail.prepare

    with_routing do |map|
      map.draw do
        concern :active_scaffold, ActiveScaffold::Routing::Basic.new
        resources :addresses, concerns: :active_scaffold
      end
      assert_routing '/addresses/deleted', controller: 'addresses', action: 'deleted'
    end
  end

  def test_paper_trail_deleted_action_authorization
    action = paper_trail_deleted_records_action
    action.expects(:list_authorized?).returns(:authorized)
    assert_equal :authorized, action.send(:deleted_authorized?)

    action.stubs(:deleted_authorized?).returns(false)
    assert_raises ActiveScaffold::ActionNotAllowed do
      action.send(:deleted_authorized_filter)
    end
  end

  def test_paper_trail_deleted_query_uses_real_version_api
    action = paper_trail_deleted_records_action
    action.stubs(:nested?).returns(false)
    destroys = mock
    query = mock
    PaperTrail::Version.expects(:destroys).returns(destroys)
    destroys.expects(:where).with(item_type: 'InstalledPaperTrailProject').returns(query)

    assert_same query, action.send(:deleted_records_query)
  end

  def test_paper_trail_deleted_action_reifies_a_paginated_version
    assert_installed_bridge(:paper_trail)
    restored_record = InstalledPaperTrailProject.new(name: 'Restored')
    version = stub(reify: restored_record)
    query = mock
    query.stubs(:count).returns(1)
    query.stubs(:offset).returns(query)
    query.stubs(:limit).returns([version])
    action = paper_trail_deleted_records_action
    action.stubs(:deleted_records_query).returns(query)
    action.stubs(:params).returns({})
    action.expects(:respond_to_action).with(:list).returns(:rendered)

    assert_equal :rendered, action.deleted
    assert_equal :deleted, action.instance_variable_get(:@pagination_action)
    assert_equal [restored_record], action.instance_variable_get(:@records)
  end

  def test_paper_trail_helper_filters_links_only_for_deleted_records
    base = Class.new do
      def display_action_links(action_links, *)
        action_links
      end
    end
    helper_class = Class.new(base) do
      include ActiveScaffold::Bridges::PaperTrail::Helper

      attr_accessor :current_action

      alias action_name current_action

      def filter_action_links_for_deleted(action_links, *)
        action_links.first(1)
      end
    end
    helper = helper_class.new
    helper.current_action = 'deleted'
    assert_equal [:show], helper.display_action_links(%i[show edit], nil, {})

    helper.current_action = 'list'
    assert_equal %i[show edit], helper.display_action_links(%i[show edit], nil, {})
  end

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

  def test_installed_select_bridges_build_select_conditions
    column = ActiveScaffold::DataStructures::Column.new('first_name', Person)

    %i[country chosen multi_chosen].each do |search_ui|
      column.search_ui = search_ui

      assert_equal ['"people"."first_name" in (?)', %w[Alice Bob]],
                   ClassWithFinder.condition_for_column(column, ['Alice', '', 'Bob'], :full, {}), search_ui
      assert_equal ['"people"."first_name" >= ?', 'M'],
                   ClassWithFinder.condition_for_column(column, {opt: '>=', from: 'M'}, :full, {}), search_ui
      assert_nil ClassWithFinder.condition_for_column(column, [], :full, {}), search_ui
    end
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

  def test_tiny_mce_bridge_renders_configuration_and_html_safely
    bridge = assert_installed_bridge(:tiny_mce)
    config = ActiveScaffold::Config::Core.new(:company)
    column = config.columns[:name]
    column.options[:tinymce] = {toolbar: 'undo redo'}
    options = {name: 'record[name]', id: 'record_name', class: 'name-input', object: Company.new}

    assert_includes bridge.javascripts, 'active_scaffold/tiny_mce_bridge'
    assert_equal ['tiny_mce_bridge'], bridge.stylesheets

    html = active_scaffold_input_tinymce(column, options)
    assert_includes html, 'class="name-input mceEditor"'
    assert_includes html, '&quot;toolbar&quot;:&quot;undo redo&quot;'
    rendered = active_scaffold_show_tinymce(Struct.new(:name).new('<strong>Safe</strong>'), column)
    assert_predicate rendered, :html_safe?
  end

  def test_tiny_mce_bridge_supports_named_configuration_and_safe_javascript
    config = ActiveScaffold::Config::Core.new(:company)
    column = config.columns[:name]
    column.options[:tinymce_config] = :alternate
    options = {name: 'record[name]', id: 'record_name', object: Company.new}

    html = active_scaffold_input_tinymce(column, options)
    assert_includes html, '&quot;theme&quot;:&quot;alternate&quot;'
    assert_includes html, '&quot;toolbar&quot;:&quot;undo redo | format&quot;'

    source = File.read(File.join(ASSETS_PATH, 'tiny_mce_bridge.js'))
    registry = File.read(File.join(ASSETS_PATH, 'callback_registry.js'))
    assert_includes registry, 'ActiveScaffold.tinymceCallbacks'
    assert_not_includes source, 'eval('
    assert_includes source, "ActiveScaffold.resolveCallback('tinymceCallbacks'"
    assert_not_includes source, 'majorVersion'
    assert_not_includes source, 'userInit'
  end

  private

  def assert_method_installed(method_name)
    assert ActionView::Base.method_defined?(method_name), "#{method_name} was not installed on ActionView::Base"
  end

  attr_reader :active_scaffold_config

  def tinymce_configuration(config = :default)
    options =
      if config == :alternate
        {'theme' => 'alternate', 'toolbar' => 'undo redo | format'}
      else
        {'selector' => '.tinymce', 'theme' => 'silver'}
      end
    Struct.new(:options).new(options)
  end

  def paper_trail_deleted_records_action
    config = stub(
      actions: [],
      model: InstalledPaperTrailProject,
      list: stub(per_page: 15)
    )
    action_class = Class.new do
      define_singleton_method(:before_action) { |*| nil }
      define_singleton_method(:active_scaffold_config) { config }
      define_method(:active_scaffold_config) { config }
      include ActiveScaffold::Actions::DeletedRecords
    end
    action_class.new
  end
end
