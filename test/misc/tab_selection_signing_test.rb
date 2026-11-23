# frozen_string_literal: true

require 'test_helper'

class TabSelectionSigningTest < ActionDispatch::IntegrationTest
  setup do
    RequestStore.clear!
    @category = Category.create!(name: 'Category')
    @project = Project.create!(name: 'Project')
    Task.create!(project: @project, category: @category, name: 'Existing')
  end

  test 'tabbed create-another links carry a valid signature' do
    url = tabbed_link
    options = options_for(url)
    payload = ActiveScaffold::ParameterSigning.tab_selection_payload(options, controller: 'projects')

    assert_match(/\A[A-Za-z0-9_-]{43}\z/, options['tab_signature'])
    assert ActiveScaffold::ParameterSigning.valid_signature?(payload, options['tab_signature'], purpose: :tab_selection)
    assert_equal @category.id.to_s, options['value']
    assert_no_difference 'Task.count' do
      get url, xhr: true
    end
    assert_response :success
  end

  test 'unsigned tab selections are rejected before assigning values' do
    ProjectsController.any_instance.expects(:assign_tabbed_by).never

    get '/projects/edit_associated.json', params: {
      id: @project.id, child_association: 'tasks', tabbed_by: 'category', value: @category.id, value_type: 'Kernel'
    }

    assert_response :bad_request
  end

  test 'changing any signed field rejects the request before assignment' do
    options = options_for(tabbed_link)
    ProjectsController.any_instance.expects(:assign_tabbed_by).never

    %w[value value_type tabbed_by child_association scope parent_controller id generated_id eid].each do |field|
      get '/projects/edit_associated.json', params: options.except('controller', 'action', 'format').merge(field => 'tampered')

      assert_response :bad_request, field
    end
  end

  test 'signatures cannot be reused in another controller' do
    options = options_for(tabbed_link).except('controller', 'action', 'format')

    get '/people/edit_associated.json', params: options

    assert_response :bad_request
  end

  test 'return signatures cannot authenticate tab selections' do
    options = options_for(tabbed_link).except('controller', 'action', 'format')
    options['tab_signature'] = ProjectsController.new.signed_return_to_options(return_to: '/projects')[:return_to_signature]

    get '/projects/edit_associated.json', params: options

    assert_response :bad_request
  end

  test 'signed tab selections also work for a new parent' do
    options = ProjectsController.new.signed_tab_selection_options(
      controller: '/projects', child_association: 'tasks', parent_controller: 'projects', generated_id: '12345',
      tabbed_by: 'category', value: @category.id
    ).except(:controller)

    get '/projects/edit_associated.js', params: options, xhr: true

    assert_response :success
    assert_equal ['Existing'], @project.tasks.reload.pluck(:name)
  end

  test 'unverified incoming tab parameters cannot get signed through generated links' do
    url = tabbed_link({tabbed_by: 'admin', value: 'forged', value_type: 'Kernel', tab_signature: 'forged'})
    options = options_for(url)

    assert_equal 'category', options['tabbed_by']
    assert_equal @category.id.to_s, options['value']
    assert_nil options['value_type']
    payload = ActiveScaffold::ParameterSigning.tab_selection_payload(options, controller: 'projects')
    assert ActiveScaffold::ParameterSigning.valid_signature?(payload, options['tab_signature'], purpose: :tab_selection)
  end

  test 'signed scalar tab selections retain their values' do
    options = ProjectsByPriorityController.new.signed_tab_selection_options(
      controller: '/projects_by_priority', id: @project.id, child_association: 'tasks', parent_controller: 'projects_by_priority',
      tabbed_by: 'priority', value: 'high'
    ).except(:controller)

    get '/projects_by_priority/edit_associated.js', params: options, xhr: true

    assert_response :success
    assert_includes response.body, 'high'
  end

  test 'signed polymorphic tab selections retain their record type' do
    person = Person.create!(first_name: 'Parent')
    options = PeopleController.new.signed_tab_selection_options(
      controller: '/people', id: person.id, child_association: 'contacts', parent_controller: 'people',
      tabbed_by: 'contactable', value: person.id, value_type: 'Person'
    ).except(:controller)

    get '/people/edit_associated.js', params: options, xhr: true

    assert_response :success
  end

  test 'ordinary un-tabbed associated forms still work without a signature' do
    get '/projects/edit_associated.js', params: {id: @project.id, child_association: 'tasks'}, xhr: true

    assert_response :success
  end

  test 'add-existing links sign their tab context and insert into the clicked tab' do
    candidate = Task.create!(name: 'Unassigned', category: @category)
    url = tabbed_link(existing: true).sub('--ID--', candidate.id.to_s)
    options = options_for(url)
    payload = ActiveScaffold::ParameterSigning.tab_selection_payload(options, controller: 'projects')

    assert ActiveScaffold::ParameterSigning.valid_signature?(payload, options['tab_signature'], purpose: :tab_selection)

    get url, xhr: true

    assert_response :success
    assert_includes response.body, "as_projects-#{@project.id}-tasks-#{@category.id}-subform-list"
    assert_nil candidate.reload.project_id
  end

  test 'add existing stages a different grouping value until the parent form is saved' do
    previous_category = Category.create!(name: 'Previous category')
    candidate = Task.create!(name: 'Unassigned', category: previous_category)
    url = tabbed_link(existing: true).sub('--ID--', candidate.id.to_s)

    get url, xhr: true

    assert_response :success
    assert_includes response.body, "as_projects-#{@project.id}-tasks-#{@category.id}-subform-list"
    html = response.body.gsub('\"', '"').gsub("\\'", "'").gsub('\\/', '/')
    selected_category = Nokogiri::HTML.fragment(html).at_css('select.category-input option[selected]')['value']
    assert_equal @category.id.to_s, selected_category
    assert_equal previous_category.id, candidate.reload.category_id
    assert_nil candidate.project_id

    patch "/projects/#{@project.id}.json", params: {
      record: {tasks: {candidate.id.to_s => {id: candidate.id, name: candidate.name, category: selected_category}}}
    }

    assert_response :success
    assert_equal @category.id, candidate.reload.category_id
    assert_equal @project.id, candidate.project_id
  end

  test 'add existing requires permission to change the grouping column' do
    previous_category = Category.create!(name: 'Previous category')
    candidate = Task.create!(name: 'Unassigned', category: previous_category)
    url = tabbed_link(existing: true).sub('--ID--', candidate.id.to_s)
    Task.any_instance.stubs(:authorized_for?).returns(true)
    Task.any_instance.stubs(:authorized_for?).with(crud_type: :update, column: :category).returns(false)

    get url, xhr: true

    assert_response :forbidden
    assert_equal previous_category.id, candidate.reload.category_id
    assert_nil candidate.project_id
  end

  test 'matching existing tab values do not require grouping update permission' do
    candidate = Task.create!(name: 'Unassigned', category: @category)
    url = tabbed_link(existing: true).sub('--ID--', candidate.id.to_s)
    Task.any_instance.stubs(:authorized_for?).returns(true)
    Task.any_instance.stubs(:authorized_for?).with(crud_type: :update, column: :category).returns(false)

    get url, xhr: true

    assert_response :success
    assert_equal @category.id, candidate.reload.category_id
    assert_nil candidate.project_id
  end

  test 'tampering with an add-existing tab selection is rejected' do
    candidate = Task.create!(name: 'Unassigned', category: @category)
    options = options_for(tabbed_link(existing: true)).except('controller', 'action', 'format')
    options['associated_id'] = candidate.id
    options['value'] = 'tampered'

    get '/projects/edit_associated.json', params: options

    assert_response :bad_request
    assert_nil candidate.reload.project_id
  end

  private

  def tabbed_link(parameters = {}, existing: false)
    get "/projects/#{@project.id}/edit", params: parameters
    assert_response :success
    links = css_select(existing ? 'a.as_add_existing[href]' : 'a.as_create_another[href]')
    link = links.find do |element|
      query = Rack::Utils.parse_nested_query(URI.parse(element['href']).query)
      query['child_association'] == 'tasks' && query['tabbed_by'] == 'category'
    end
    assert link, 'Expected an association link for the tasks tab'
    link['href']
  end

  def options_for(url)
    uri = URI.parse(url)
    Rails.application.routes.recognize_path(uri.path).stringify_keys.merge(Rack::Utils.parse_nested_query(uri.query))
  end
end

class RecordSelectTabSigningTest < ActiveSupport::TestCase
  test 'record-select callbacks preserve and sign the destination tab' do
    helper = Object.new.extend(ActiveScaffold::Helpers::AssociationHelpers)
    helper.extend(ActiveScaffold::Helpers::ControllerHelpers)
    helper.define_singleton_method(:controller_path) { 'projects' }
    helper.define_singleton_method(:active_scaffold_id) { 'as_projects' }
    generated = []
    helper.define_singleton_method(:url_for) do |options|
      generated << options
      '/projects/edit_associated'
    end
    options = {
      controller: '/projects', id: '1', child_association: 'tasks', associated_id: '--ID--',
      tabbed_by: 'category', value: '2'
    }

    [true, false].each do |registry|
      ActiveScaffold::Bridges::RecordSelect.stubs(:callback_registry?).returns(registry)
      helper.record_select_params_for_add_existing(nil, options, nil)
      signed = generated.last
      payload = ActiveScaffold::ParameterSigning.tab_selection_payload(signed.merge(associated_id: '3'), controller: 'projects')

      assert_equal 'category', signed[:tabbed_by]
      assert_equal '2', signed[:value]
      assert ActiveScaffold::ParameterSigning.valid_signature?(payload, signed[:tab_signature], purpose: :tab_selection)
    end
    assert_not options.key?(:tab_signature)
  end
end

class AddTabValidationTest < ActionDispatch::IntegrationTest
  setup do
    RequestStore.clear!
    @category = Category.create!(name: 'Allowed category')
  end

  test 'browser-selected values from configured options can add tabs without a signature' do
    post '/projects/render_field.js', params: {column: 'Assignments', tabbed_by: 'category', value: @category.id}, xhr: true

    assert_response :success
    assert_includes response.body, 'Allowed category'
    assert_includes response.body, 'tab_signature='
  end

  test 'unknown option values do not render tabs or mint signatures' do
    post '/projects/render_field.js', params: {column: 'Assignments', tabbed_by: 'category', value: 'unknown'}, xhr: true

    assert_response :success
    assert_empty response.body.strip
  end

  test 'scalar tab options can be selected by the browser' do
    post '/projects_by_priority/render_field.js', params: {column: 'Tasks by Priority', tabbed_by: 'priority', value: 'high'}, xhr: true

    assert_response :success
    assert_includes response.body, 'High'
    assert_includes response.body, 'tab_signature='
  end

  test 'requests cannot change the configured grouping field' do
    post '/projects/render_field.json', params: {column: 'Assignments', tabbed_by: 'admin', value: '1'}

    assert_response :bad_request
  end

  test 'requests cannot use ordinary columns as tab groups' do
    post '/projects/render_field.json', params: {column: 'name', tabbed_by: 'name', value: 'forged'}

    assert_response :bad_request
  end
end
