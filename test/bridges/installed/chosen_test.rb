# frozen_string_literal: true

require_relative 'test_helper'

class InstalledChosenBridgeTest < InstalledBridgeTestCase
  include ActiveScaffold::Bridges::Chosen::Helpers

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
end
