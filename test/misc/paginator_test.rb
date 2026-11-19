# frozen_string_literal: true

require 'test_helper'

class PaginatorTest < ActiveSupport::TestCase
  def test_requires_a_selection_block
    error = assert_raises(Paginator::MissingSelectError) { Paginator.new(5, 2) }

    assert_equal 'Must provide block to select data for each page', error.message
  end

  def test_builds_pages_and_passes_offset_and_limit_to_the_selection_block
    calls = []
    pager = Paginator.new(5, 2) do |offset, limit|
      calls << [offset, limit]
      (1..5).to_a.slice(offset, limit)
    end

    assert_equal 3, pager.number_of_pages
    assert_equal [1, 2], pager.first.items
    assert_equal [5], pager.last.items
    assert_equal [[0, 2], [4, 2]], calls
  end

  def test_page_navigation_item_numbers_and_equality
    pager = Paginator.new(5, 2) { |offset, limit| (1..5).to_a.slice(offset, limit) }
    page = pager.page(2)

    assert_predicate page, :prev?
    assert_predicate page, :next?
    assert_equal pager.page(1), page.prev
    assert_equal pager.page(3), page.next
    assert_equal 3, page.first_item_number
    assert_equal 4, page.last_item_number
    assert_nil pager.first.prev
    assert_nil pager.last.next
    assert_equal 5, pager.last.last_item_number
    assert_equal pager.first, pager.page(0)
    assert_not_equal pager.first, page
  end

  def test_iterates_over_pages_and_items_and_caches_selected_items
    selections = 0
    pager = Paginator.new(3, 2) do |offset|
      selections += 1
      (1..3).to_a.slice(offset, 2)
    end
    page = pager.first

    page_items = []
    page.each { |item| page_items << item } # rubocop:disable Style/MapIntoArray -- Page is not Enumerable
    indexed_items = []
    page.each_with_index { |item, index| indexed_items << [item, index] }
    assert_equal [1, 2], page_items
    assert_equal [[1, 0], [2, 1]], indexed_items
    assert_equal [1, 2], page.items
    assert_equal 1, selections
    indexed_pages = []
    pager.each_with_index { |item, index| indexed_pages << [item, index] }
    pages = []
    pager.each { |item| pages << item } # rubocop:disable Style/MapIntoArray -- Paginator is not Enumerable
    assert_equal [[pager.first, 0], [pager.last, 1]], indexed_pages
    assert_equal [pager.first, pager.last], pages
  end

  def test_active_scaffold_extensions_support_an_unknown_count
    pager = Paginator.new(nil, 2) { |offset, limit| [1, 2, 3].slice(offset, limit) || [] }
    page = pager.first

    assert_predicate pager, :infinite?
    assert_nil pager.number_of_pages
    assert_equal 2, pager.count
    assert_predicate page, :next?
    assert_not_predicate page, :empty?
    assert_predicate pager.page(3), :empty?
  end
end
