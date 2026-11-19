# frozen_string_literal: true

require 'test_helper'

class FilterTest < ActiveSupport::TestCase
  setup do
    @filter = ActiveScaffold::DataStructures::Filter.new('visibility', :links)
  end

  test 'initializes filter attributes and validates its name' do
    assert_equal :visibility, @filter.name
    assert_equal :links, @filter.type
    assert_equal 0, @filter.weight
    assert_empty @filter
    assert_not_predicate @filter, :security_method_set?

    assert_raises(ArgumentError) do
      ActiveScaffold::DataStructures::Filter.new('invalid name', :links)
    end
  end

  test 'adds and finds generated options while selecting the first by default' do
    result = @filter.add(:all, conditions: {visible: [true, false]})
    @filter << :visible

    assert_same @filter, result
    assert_equal :all, @filter.default_option
    assert_equal %i[all visible], @filter.map(&:name)
    assert_equal({visible: [true, false]}, @filter[:all].conditions)
    assert_same @filter[:visible], @filter['visible']
  end

  test 'accepts an existing option and rejects duplicate names' do
    option = ActiveScaffold::DataStructures::FilterOption.new(:visibility, :all)

    @filter.add(option)

    assert_same option, @filter[:all]
    error = assert_raises(ArgumentError) { @filter.add('all') }
    assert_equal "there is a filter option with 'all' name", error.message
  end

  test 'changes the default only to an existing option' do
    @filter.add(:all).add(:visible)

    @filter.default_option = 'visible'
    assert_equal :visible, @filter.default_option

    error = assert_raises(ArgumentError) { @filter.default_option = :missing }
    assert_equal "'missing' option not found", error.message
  end

  test 'deletes options by string or symbol name' do
    @filter.add(:all).add(:visible)

    assert_equal :all, @filter.delete('all').name
    assert_nil @filter[:all]
    assert_equal [:visible], @filter.map(&:name)
    assert_nil @filter.delete(:missing)
  end

  test 'translates symbolic labels and descriptions and preserves strings' do
    I18n.backend.store_translations(
      :en,
      active_scaffold: {
        filter_test_label: 'Visibility filter',
        filter_test_description: 'Restrict visible records'
      }
    )
    @filter.label = :filter_test_label
    @filter.description = :filter_test_description

    assert_equal 'Visibility filter', @filter.label
    assert_equal 'Restrict visible records', @filter.description

    @filter.label = 'Visibility'
    @filter.description = 'Choose visibility'
    assert_equal 'Visibility', @filter.label
    assert_equal 'Choose visibility', @filter.description
  end

  test 'reports an explicitly configured security method' do
    @filter.security_method = :visibility_filter_allowed?

    assert_predicate @filter, :security_method_set?
  end

  test 'deeply clones its options' do
    @filter.add(:all).add(:visible)

    copy = @filter.clone

    assert_equal @filter.map(&:name), copy.map(&:name)
    assert_not_same @filter[:all], copy[:all]
    copy.delete(:all)
    assert @filter[:all]
    assert_nil copy[:all]
  end
end
