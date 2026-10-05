# frozen_string_literal: true

require 'test_helper'

class FrameworkUiHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ActionLinkHelpers
  include ActiveScaffold::Helpers::FrameworkUiHelpers

  setup do
    @ui_elements = ActiveScaffold.ui_elements.deep_dup
  end

  teardown do
    ActiveScaffold.ui_elements.replace(@ui_elements)
  end

  def test_as_element_uses_configured_tag_and_merges_attributes
    ActiveScaffold.ui_elements[:test_element] = {
      tag: :section,
      attributes: {class: 'configured', data: {controller: 'test'}}
    }

    html = as_element(:test_element, 'content', class: 'rendered', data: {action: 'click->test#run'})

    assert_dom_equal <<~HTML, html
      <section class="configured rendered" data-controller="test" data-action="click-&gt;test#run">content</section>
    HTML
  end

  def test_as_element_renders_a_block
    ActiveScaffold.ui_elements[:test_element] = {tag: :article}

    assert_dom_equal '<article><strong>content</strong></article>', as_element(:test_element) { tag.strong('content') }
  end

  def test_as_element_attributes_does_not_include_the_tag
    ActiveScaffold.ui_elements[:test_element] = {tag: :div, attributes: {class: 'configured'}}

    assert_equal({class: 'configured rendered'}, as_element_attributes(:test_element, class: 'rendered'))
  end

  def test_default_registry_attributes_are_available
    assert_equal 'form-columns', as_element_attributes(:field_search_fields_columns)[:class]
  end

  def test_set_element_tag
    ActiveScaffold.ui_elements[:test_element] = {tag: :div}

    ActiveScaffold.set_element_tag(:test_element, :section)

    assert_dom_equal '<section>content</section>', as_element(:test_element, 'content')
  end

  def test_set_element_replaces_the_complete_definition
    ActiveScaffold.ui_elements[:test_element] = {
      tag: :div,
      attributes: {class: 'old'},
      proc: ->(_) { [:aside, {class: 'dynamic'}] }
    }

    ActiveScaffold.set_element(:test_element, tag: :section, attributes: {class: 'new'})

    assert_equal({tag: :section, attributes: {class: 'new'}}, ActiveScaffold.ui_elements[:test_element])
    assert_dom_equal '<section class="new">content</section>', as_element(:test_element, 'content')
  end

  def test_set_element_accepts_a_proc
    ActiveScaffold.set_element(:test_element) do |context|
      [context.fetch(:tag), {class: 'dynamic'}]
    end

    assert_dom_equal '<aside class="dynamic">content</aside>',
                     as_element(:test_element, 'content', proc_options: {tag: :aside})
  end

  def test_set_element_rejects_static_and_dynamic_definitions_together
    error = assert_raises(ArgumentError) do
      ActiveScaffold.set_element(:test_element, tag: :div) { [:section, {}] }
    end

    assert_equal 'tag and attributes cannot be used with a proc', error.message
  end

  def test_set_element_attributes_replaces_configured_attributes
    ActiveScaffold.ui_elements[:test_element] = {
      tag: :div,
      attributes: {class: 'old', data: {controller: 'old'}}
    }

    ActiveScaffold.set_element_attributes(:test_element, class: 'new')

    assert_equal({class: 'new'}, ActiveScaffold.ui_elements[:test_element][:attributes])
    assert_dom_equal '<div class="new rendered">content</div>',
                     as_element(:test_element, 'content', class: 'rendered')
  end

  def test_add_element_attributes_merges_classes_and_nested_attributes
    ActiveScaffold.ui_elements[:test_element] = {
      tag: :div,
      attributes: {class: 'existing', data: {controller: 'existing'}}
    }

    ActiveScaffold.add_element_attributes(
      :test_element,
      class: 'added', data: {action: 'click->test#run'}
    )

    assert_equal(
      {class: 'existing added', data: {controller: 'existing', action: 'click->test#run'}},
      ActiveScaffold.ui_elements[:test_element][:attributes]
    )
  end

  def test_element_proc_runs_in_view_context_and_receives_proc_options
    ActiveScaffold.set_element_proc(:test_element) do |context|
      [context.fetch(:tag), {class: element_class(context.fetch(:name))}]
    end

    html = as_element(
      :test_element,
      'content',
      proc_options: {tag: :aside, name: 'dynamic'},
      class: 'rendered'
    )

    assert_dom_equal '<aside class="from-dynamic rendered">content</aside>', html
  end

  def test_action_link_element_receives_explicit_authorized_state
    contexts = []
    ActiveScaffold.set_element_proc(:action_link) do |context|
      contexts << context
      [nil, {class: context[:authorized] ? 'authorized' : 'unauthorized'}]
    end
    link = Object.new
    record = Object.new
    options = {page: true}

    authorized = action_link_element_attributes(link, record, options, {}, authorized: true)
    unauthorized = action_link_element_attributes(link, record, options, {}, authorized: false)

    assert_equal 'authorized', authorized[:class]
    assert_equal 'unauthorized', unauthorized[:class]
    assert_equal [true, false], contexts.pluck(:authorized)
    assert_same link, contexts.first[:link]
    assert_same record, contexts.first[:record]
    assert_same options, contexts.first[:options]
  end

  def test_proc_attributes_take_precedence_over_static_attributes
    ActiveScaffold.ui_elements[:test_element] = {
      tag: :div,
      attributes: {class: 'static'},
      proc: ->(_) { [:section, {class: 'dynamic'}] }
    }

    assert_dom_equal '<section class="dynamic rendered">content</section>',
                     as_element(:test_element, 'content', class: 'rendered')
  end

  private

  def element_class(name)
    "from-#{name}"
  end
end
