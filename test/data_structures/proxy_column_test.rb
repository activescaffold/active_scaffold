# frozen_string_literal: true

require 'test_helper'

class ProxyColumnTest < ActiveSupport::TestCase
  setup do
    @column = ActiveScaffold::DataStructures::Column.new(:a, ModelStub)
    @proxy = ActiveScaffold::DataStructures::ProxyColumn.new(@column)
  end

  test 'delegates column configuration until it is overridden' do
    @column.required = true
    @column.css_class = 'source'

    assert_predicate @proxy, :required?
    assert_equal 'source', @proxy.css_class

    @proxy.required = false
    @proxy.css_class = 'proxy'

    assert_not_predicate @proxy, :required?
    assert_equal 'proxy', @proxy.css_class
    assert_predicate @column, :required?
    assert_equal 'source', @column.css_class
  end

  test 'copies UI configuration whose fallbacks depend on instance variables' do
    @column.form_ui = [:textarea, {rows: 3}]
    @column.list_ui = [:truncate, {length: 20}]
    @column.show_ui = [:code, {language: :ruby}]
    @column.search_ui = [:text, {autocomplete: false}]
    @column.search_joins = :project

    proxy = ActiveScaffold::DataStructures::ProxyColumn.new(@column)

    assert_equal :textarea, proxy.form_ui
    assert_equal({rows: 3}, proxy.form_ui_options)
    assert_equal :truncate, proxy.list_ui
    assert_equal({length: 20}, proxy.list_ui_options)
    assert_equal :code, proxy.show_ui
    assert_equal({language: :ruby}, proxy.show_ui_options)
    assert_equal :text, proxy.search_ui
    assert_equal({autocomplete: false}, proxy.search_ui_options)
    assert_equal [:project], proxy.search_joins
  end

  test 'delegates column methods and preserves column identity' do
    assert_equal :a, @proxy.name
    assert_respond_to @proxy, :active_record_class
    assert_equal ModelStub, @proxy.active_record_class
    assert_equal @column, @proxy
    assert @proxy.is_a?(ActiveScaffold::DataStructures::Column)
    assert_raises(NoMethodError) { @proxy.unknown_column_method }
  end

  test 'normalizes configured params into an independent set' do
    @proxy.params = %i[first second first]

    assert_equal %i[first second], @proxy.params.to_a
    assert_empty @column.params
  end
end
