# frozen_string_literal: true

require 'test_helper'

class ViewHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ViewHelpers

  def test_history_state_includes_user_sorting
    column = stub(name: :last_name)
    sorting = stub(first: [column, :desc])
    user = stub(user_sorting?: true, sorting: sorting)
    @config = stub(store_user_settings: true, list: stub(user: user))
    @page = stub(number: 4)

    assert_equal({page: 4, sort: :last_name, sort_direction: :desc}, history_state)
  end

  def test_display_message_highlights_phrases_and_adds_timestamp
    user = stub(
      highlight_messages: {['urgent'] => {highlighter: '<strong>\\1</strong>'}},
      timestamped_messages: true
    )
    @config = stub(user: user)

    fragment = Nokogiri::HTML.fragment(display_message('An urgent update'))

    assert_predicate fragment.at_css('div.timestamp').text, :present?
    assert_equal 'An urgent update', fragment.at_css('div.message-content').text
    assert_equal 'urgent', fragment.at_css('div.message-content strong').text
  end

  def test_column_class_supports_static_and_callable_css_classes
    sorting = stub(sorts_on?: false)
    @config = stub(actions: [:list], list: stub(user: stub(sorting: sorting)))
    stubs(:column_empty?).returns(false)
    stubs(:inplace_edit?).returns(false)
    static_column = ActiveScaffold::DataStructures::Column.new(:b, ModelStub)
    static_column.css_class = 'important'
    callable_column = ActiveScaffold::DataStructures::Column.new(:c, ModelStub)
    callable_column.css_class = ->(value, record) { "#{value}-#{record.id}" }
    record = ModelStub.new(id: 7)

    assert_includes column_class(static_column, 'value', record), 'important'
    assert_includes column_class(callable_column, 'active', record), 'active-7'
  end

  private

  def active_scaffold_config
    @config
  end
end
