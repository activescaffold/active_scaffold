require 'test_helper'

class ListColumnHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ListColumnHelpers
  include ActiveScaffold::Helpers::ViewHelpers
  include ::ERB::Util

  def setup
    @column = ActiveScaffold::DataStructures::Column.new(:a, ModelStub)
    @column.form_ui = :select
    @record = stub(:a => 'value_2')
    @config = stub(:list => stub(:empty_field_text => '-', :association_join_text => ', '), :actions => [:list])
    @association_column = ActiveScaffold::DataStructures::Column.new(:b, ModelStub)
    @association_column.stubs(:association).returns(stub(:collection? => true))
  end

  def test_options_for_select_list_ui_for_simple_column
    @column.options[:options] = %i[value_1 value_2 value_3]
    assert_equal 'Value 2', format_column_value(@record, @column)

    @column.options[:options] = %w[value_1 value_2 value_3]
    assert_equal 'value_2', format_column_value(@record, @column)

    @column.options[:options] = [%w[text_1 value_1], %w[text_2 value_2], %w[text_3 value_3]]
    assert_equal 'text_2', format_column_value(@record, @column)

    @column.options[:options] = [%i[text_1 value_1], %i[text_2 value_2], %i[text_3 value_3]]
    assert_equal 'Text 2', format_column_value(@record, @column)
  end

  def test_association_join_text
    value = [1, 2, 3, 4].map(&:to_s)
    value.stubs(loaded?: true)
    value.each { |v| v.stubs(:to_label).returns(v) }
    assert_equal '1, 2, 3, … (4)', format_association_value(value, @association_column, value.size)
    @config.list.stubs(:association_join_text => ',<br/>')
    remove_instance_variable :@_association_join_text
    assert_equal '1,&lt;br/&gt;2,&lt;br/&gt;3,&lt;br/&gt;… (4)', format_association_value(value, @association_column, value.size)
    @config.list.stubs(:association_join_text => ',<br/>'.html_safe) # rubocop:disable Rails/OutputSafety
    remove_instance_variable :@_association_join_text
    assert_equal '1,<br/>2,<br/>3,<br/>… (4)', format_association_value(value, @association_column, value.size)
  end

  private

  def grouped_search?
    false
  end

  def active_scaffold_config
    @config
  end
end
