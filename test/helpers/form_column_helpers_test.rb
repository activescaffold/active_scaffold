# frozen_string_literal: true

require 'test_helper'

class FormColumnHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::FormColumnHelpers
  include ActiveScaffold::Helpers::ViewHelpers

  def setup
    @column = ActiveScaffold::DataStructures::Column.new(:a, ModelStub)
    @record = ModelStub.new(a: nil)
  end

  def a_form_column(*)
    content_tag(:input, nil, name: 'record[a]').freeze
  end

  def test_form_attribute_html_does_not_modify_frozen_custom_form_column
    field = active_scaffold_render_input(@column, object: @record)
    description = content_tag(:span, 'Description')

    assert_predicate field, :frozen?
    assert_dom_equal '<dl><dt>Label</dt><dd><input name="record[a]"><span>Description</span></dd></dl>',
                     form_attribute_html(@column, 'Label', field, description, {})
  end

  def test_choices_for_select_form_ui_for_simple_column
    opts = {object: @record}
    @column.options[:options] = %i[value_1 value_2 value_3]
    assert_dom_equal "<select name=\"record[a]\" id=\"record_a\"><option value=\"value_1\">Value 1</option>\n<option value=\"value_2\">Value 2</option>\n<option value=\"value_3\">Value 3</option></select>", active_scaffold_input_select(@column, opts.dup)

    @column.options[:options] = %w[value_1 value_2 value_3]
    assert_dom_equal "<select name=\"record[a]\" id=\"record_a\"><option value=\"value_1\">value_1</option>\n<option value=\"value_2\">value_2</option>\n<option value=\"value_3\">value_3</option></select>", active_scaffold_input_select(@column, opts.dup)

    @column.options[:options] = [%w[text_1 value_1], %w[text_2 value_2], %w[text_3 value_3]]
    assert_dom_equal "<select name=\"record[a]\" id=\"record_a\"><option value=\"value_1\">text_1</option>\n<option value=\"value_2\">text_2</option>\n<option value=\"value_3\">text_3</option></select>", active_scaffold_input_select(@column, opts.dup)

    @column.options[:options] = [%i[text_1 value_1], %i[text_2 value_2], %i[text_3 value_3]]
    assert_dom_equal "<select name=\"record[a]\" id=\"record_a\"><option value=\"value_1\">Text 1</option>\n<option value=\"value_2\">Text 2</option>\n<option value=\"value_3\">Text 3</option></select>", active_scaffold_input_select(@column, opts.dup)
  end

  def test_options_for_select_form_ui_for_simple_column
    opts = {object: @record}
    @column.options = {include_blank: 'None', selected: 'value_2', disabled: %w[value_1 value_3]}
    @column.options[:options] = %w[value_1 value_2 value_3]
    @column.options[:html_options] = {class: 'big'}
    assert_dom_equal "<select name=\"record[a]\" class=\"big\" id=\"record_a\"><option value=\"\">None</option>\n<option disabled=\"disabled\" value=\"value_1\">value_1</option>\n<option selected=\"selected\" value=\"value_2\">value_2</option>\n<option disabled=\"disabled\" value=\"value_3\">value_3</option></select>", active_scaffold_input_select(@column, opts)
  end
end
