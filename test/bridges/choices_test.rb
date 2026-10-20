# frozen_string_literal: true

require 'test_helper'

class ChoicesTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ViewHelpers
  include ActiveScaffold::Bridges::Choices::Helpers

  def test_bridge_is_enabled_and_adds_adapter
    assert_predicate ActiveScaffold::Bridges::Choices, :install?
    assert_includes ActiveScaffold::Bridges.all_javascripts, 'active_scaffold/choices'
    assert_respond_to self, :active_scaffold_human_condition_choices
    assert_respond_to self, :active_scaffold_human_condition_multi_choices
  end

  def test_form_ui_adds_bridge_class
    config = ActiveScaffold::Config::Core.new(:company)
    column = config.columns[:name]
    column.options[:options] = %w[one two]
    column.options[:html_options] = {class: 'custom-select'}
    options = {name: 'record[name]', id: 'record_name', class: 'name-input', object: Company.new}

    html = active_scaffold_input_choices(column, options)

    assert_includes html, 'class="name-input custom-select as-choices"'
  end

  def test_search_ui_adds_bridge_class_and_multiple_attribute
    config = ActiveScaffold::Config::Core.new(:company)
    column = config.columns[:name]
    column.options[:options] = %w[one two]
    column.options[:null_comparators] = false
    options = {name: 'search[name]', id: 'search_name', class: 'name-input', object: Company.new}

    html = active_scaffold_search_multi_choices(column, options)

    assert_includes html, 'class="name-input as-choices"'
    assert_includes html, 'multiple="multiple"'
  end

  def test_collection_association_uses_multiple_select
    config = ActiveScaffold::Config::Core.new(:person)
    @active_scaffold_config = config
    column = config.columns[:roles]
    options = {name: 'record[roles]', id: 'record_roles', class: 'roles-input', object: Person.new}

    html = active_scaffold_input_choices(column, options)

    assert_includes html, 'class="roles-input as-choices"'
    assert_includes html, 'multiple="multiple"'
    assert_includes html, 'name="record[roles][]"'
  end

  private

  attr_reader :active_scaffold_config
end
