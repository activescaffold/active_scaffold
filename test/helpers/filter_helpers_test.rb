# frozen_string_literal: true

require 'test_helper'

class FilterHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::FilterHelpers

  def test_display_filter_as_select_renders_urls_selection_and_metadata
    filter = ActiveScaffold::DataStructures::Filter.new(:status, :select)
    filter.label = 'Status'
    filter.description = 'Filter by status'
    filter.css_class = 'status-filter'
    filter.add(:open, label: 'Open', description: 'Open records')
    filter.add(:closed, label: 'Closed')
    stubs(:action_link_url).with(filter[:open], nil).returns('/records?status=open')
    stubs(:action_link_url).with(filter[:closed], nil).returns('/records?status=closed')
    stubs(:action_link_selected?).with(filter[:open], nil).returns(true)
    stubs(:action_link_selected?).with(filter[:closed], nil).returns(false)

    fragment = Nokogiri::HTML.fragment(display_filter(filter))
    select = fragment.at_css('select.action_group.status-filter')
    open_option = select.css('option').find { |option| option.text == 'Open' }
    closed_option = select.css('option').find { |option| option.text == 'Closed' }

    assert_equal 'Filter by status', select['title']
    assert_equal 'url', select['data-remote']
    assert_equal '/records?status=open', open_option['data-url']
    assert_equal 'selected', open_option['selected']
    assert_equal 'Open records', open_option['title']
    assert_equal '/records?status=closed', closed_option['data-url']
  end
end
