# frozen_string_literal: true

require 'test_helper'

class ListColumnHelpersTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ListColumnHelpers
  include ActiveScaffold::Helpers::FormColumnHelpers
  include ActiveScaffold::Helpers::ViewHelpers
  include ::ERB::Util

  def setup
    RequestStore.clear!
    @column = ActiveScaffold::DataStructures::Column.new(:a, ModelStub)
    @column.form_ui = :select
    @record = stub(a: 'value_2')
    @config = stub(list: stub(empty_field_text: '-', association_join_text: ', '), actions: [:list])
    @association_column = ActiveScaffold::DataStructures::Column.new(:b, ModelStub)
    @association_column.stubs(:association).returns(stub(collection?: true))
  end

  def model_stub_c_column(record, _column)
    "Override: #{record.c}"
  end

  def model_stub_c_form_column(_record, _options)
    'custom form field'
  end

  def test_options_for_select_list_ui_for_simple_column
    @column.options[:options] = %i[value_1 value_2 value_3]
    assert_equal 'Value 2', get_column_value(@record, @column)

    @column.options[:options] = %w[value_1 value_2 value_3]
    assert_equal 'value_2', get_column_value(@record, @column)

    @column.options[:options] = [%w[text_1 value_1], %w[text_2 value_2], %w[text_3 value_3]]
    assert_equal 'text_2', get_column_value(@record, @column)

    @column.options[:options] = [%i[text_1 value_1], %i[text_2 value_2], %i[text_3 value_3]]
    assert_equal 'Text 2', get_column_value(@record, @column)
  end

  def test_association_join_text
    value = [1, 2, 3, 4].map(&:to_s)
    value.stubs(loaded?: true)
    value.each { |v| v.stubs(:to_label).returns(v) }
    assert_equal '1, 2, 3, … (4)', format_association_value(value, @association_column, value.size)
    @config.list.stubs(association_join_text: ',<br/>')
    remove_instance_variable :@_association_join_text
    assert_equal '1,&lt;br/&gt;2,&lt;br/&gt;3,&lt;br/&gt;… (4)', format_association_value(value, @association_column, value.size)
    @config.list.stubs(association_join_text: ',<br/>'.html_safe)
    remove_instance_variable :@_association_join_text
    assert_equal '1,<br/>2,<br/>3,<br/>… (4)', format_association_value(value, @association_column, value.size)
  end

  def test_formats_grouped_search_results
    record = stub(a: '202402')
    record.stubs(:[]).with(:a).returns('202402')
    stubs(:grouped_search?).returns(true)
    stubs(:search_group_column).returns(@column)
    stubs(:search_group_function).returns('year_month')

    assert_equal I18n.l(Date.new(2024, 2, 1), format: :year_month), format_column_value(record, @column)
  end

  def test_formats_each_grouped_search_function
    grouped_values = {
      'year_quarter' => [
        '20242',
        I18n.t(:year_quarter, scope: 'date.formats', year: '2024', quarter: '2')
      ],
      'quarter' => [3, I18n.t(:quarter, scope: 'date.formats', num: 3)],
      'month' => [2, I18n.l(Date.new(Time.zone.today.year, 2, 1), format: :month)],
      'year' => ['2024', 2024],
      'unsupported' => %w[unchanged unchanged]
    }

    grouped_values.each do |function, (value, expected)|
      @search_group_function = function
      assert_equal expected, format_grouped_search_column(value), function
    end
  end

  def test_grouped_search_format_can_be_overridden
    @search_group_function = 'year_month'

    assert_equal I18n.l(Date.new(2024, 2, 1), format: :short),
                 format_grouped_search_column('202402', group_format: :short)
  end

  def test_reads_grouped_search_results_from_each_grouped_expression
    @column.group_by = %w[first_name last_name]
    record = stub(a: 'unused')
    record.stubs(:[]).with('a_0').returns('Alice')
    record.stubs(:[]).with('a_1').returns('Example')
    stubs(:grouped_search?).returns(true)
    stubs(:search_group_column).returns(@column)
    stubs(:search_group_function).returns(nil)

    assert_equal 'Alice - Example', read_value_from_record(record, @column)
  end

  def test_formats_numbers_with_configured_format
    expects(:number_to_human_size).with(2048, {precision: 2}).returns('2 KB')
    expects(:number_to_percentage).with(25, {precision: 0}).returns('25%')
    expects(:number_to_currency).with(12.5, {unit: '€'}).returns('€12.50')

    assert_equal '2 KB', format_number_value(2048, format: :size, i18n_options: {precision: 2})
    assert_equal '25%', format_number_value(25, format: :percentage, i18n_options: {precision: 0})
    assert_equal '€12.50', format_number_value(12.5, format: :currency, i18n_options: {unit: '€'})
  end

  def test_formats_all_records_when_association_has_no_limit
    @association_column.associated_limit = nil
    values = [stub(to_label: 'First'), stub(to_label: 'Second')]

    assert_equal 'First, Second', format_association_value(values, @association_column, nil)
  end

  def test_formats_polymorphic_association_with_model_name
    person = Person.new(first_name: 'Alice', last_name: 'Example')
    person.stubs(:to_label).returns('Alice Example')
    column = ActiveScaffold::DataStructures::Column.new(:contactable, Contact)

    assert_equal 'Person: Alice Example', format_association_value(person, column, nil)
  end

  def test_formats_boolean_columns_with_translated_values
    expects(:as_).with(true.to_s.to_sym).returns('Yes')
    expects(:as_).with(false.to_s.to_sym).returns('No')

    assert_equal 'Yes', format_value(true)
    assert_equal 'No', format_value(false)
  end

  def test_heading_keeps_search_when_user_settings_are_not_stored
    @config.stubs(:store_user_settings).returns(false)
    @column.stubs(sortable?: true, label: 'A')
    stubs(:controller_id).returns('people')
    stubs(:search_params).returns('first_name' => 'Alice')
    url_options = {}
    expected_params = {
      action: :index,
      page: 1,
      sort: :a,
      sort_direction: :asc
    }
    expects(:params_for).with(expected_params).returns(url_options)
    stubs(:link_to).returns('heading')

    assert_equal 'heading', column_heading_value(@column, nil, :asc)
    assert_equal({'first_name' => 'Alice'}, url_options[:search])
  end

  def test_uses_column_helper_override
    column = ActiveScaffold::DataStructures::Column.new(:c, ModelStub)
    record = stub(c: 'custom')

    assert_equal 'Override: custom', get_column_value(record, column)
  end

  def test_text_column_uses_truncated_text_renderer_without_list_ui
    column = stub(
      name: :notes,
      active_record_class: ModelStub,
      delegated_association: nil,
      cache_key: 'text-column-without-list-ui',
      list_ui: nil,
      column: stub(type: :text),
      column_type: :text,
      options: {truncate: 8}
    )

    assert_equal 'This ...', get_column_value(stub(notes: 'This is a long note'), column)
  end

  def test_fulltext_list_ui_does_not_truncate_text
    @column.list_ui = :fulltext

    assert_equal 'This is a long value', get_column_value(stub(a: 'This is a long value'), @column)
  end

  def test_marked_list_ui_renders_selectable_checkbox
    @column.list_ui = :marked
    record = stub(a: true, to_param: '42')

    fragment = Nokogiri::HTML.fragment(get_column_value(record, @column))
    span = fragment.at_css('span.in_place_editor_field[data-ie-id="42"]')

    assert span
    assert span.at_css('input[type="checkbox"]')
  end

  def test_checkbox_list_ui_renders_disabled_checkbox
    @column.list_ui = :checkbox
    stubs(:inplace_edit?).returns(false)

    fragment = Nokogiri::HTML.fragment(get_column_value(stub(a: true), @column))

    assert fragment.at_css('input[type="checkbox"][disabled="disabled"][checked="checked"]')
  end

  def test_checkbox_list_ui_renders_enabled_checkbox_inside_inplace_editor
    column = ActiveScaffold::DataStructures::Column.new(:d, ModelStub)
    column.list_ui = :checkbox
    column.inplace_edit = true
    record = ModelStub.new(id: 42, d: true)
    stubs(:inplace_edit?).with(record, column).returns(true)
    stubs(:element_cell_id).returns('model-stubs-update-column---ID---d-cell')
    stubs(:as_).with(:click_to_edit).returns('Click to edit')
    stubs(:as_).with(:inplace_edit_handle).returns('Edit')

    value = get_column_value(record, column)
    fragment = Nokogiri::HTML.fragment(render_list_column(value, column, record))
    checkbox = fragment.at_css('span.in_place_editor_field[data-ie-id="42"] input[type="checkbox"]')

    assert checkbox
    assert_nil checkbox['disabled']
    assert_equal 'checked', checkbox['checked']
  end

  def test_checkboxes_list_ui_labels_non_association_values
    @column.form_ui = :checkboxes
    @column.options[:options] = [%w[First first], %w[Second second]]

    html = get_column_value(stub(a: %w[first second]), @column)

    assert_dom_equal '<ul><li>First</li><li>Second</li></ul>', html
  end

  def test_multiple_select_list_ui_labels_non_association_values
    @column.list_ui = [:select, {multiple: true}]
    @column.options[:options] = [%w[First first], %w[Second second]]

    html = get_column_value(stub(a: %w[first second]), @column)

    assert_dom_equal '<ul><li>First</li><li>Second</li></ul>', html
  end

  def test_radio_list_ui_labels_non_association_value
    @column.list_ui = :radio
    @column.options[:options] = [%w[First first], %w[Second second]]

    assert_equal 'Second', get_column_value(stub(a: 'second'), @column)
  end

  def test_boolean_list_ui_displays_configured_blank_value
    @column.list_ui = [:boolean, {include_blank: :unknown}]
    expects(:as_).with(:unknown).returns('Unknown')

    assert_equal 'Unknown', get_column_value(stub(a: nil), @column)
  end

  def test_boolean_list_ui_formats_true_and_false_values
    @column.list_ui = :boolean
    expects(:as_).with(true.to_s.to_sym).returns('Yes')
    expects(:as_).with(false.to_s.to_sym).returns('No')

    assert_equal 'Yes', get_column_value(stub(a: true), @column)
    assert_equal 'No', get_column_value(stub(a: false), @column)
  end

  def test_percentage_list_ui_uses_record_methods_for_slider_values
    @column.list_ui = [:percentage, {slider: {min_method: :minimum, max_method: :maximum,
                                              value_method: :current}}]
    record = stub(a: 20, minimum: 10, maximum: 90, current: 30)

    html = get_column_value(record, @column)
    slider = Nokogiri::HTML.fragment(html).at_css('.as-slider')['data-slider']

    assert_includes slider, '"min":10'
    assert_includes slider, '"max":90'
    assert_includes slider, '"value":30'
  end

  def test_month_and_week_list_ui_use_their_named_formats
    value = Date.new(2024, 2, 19)
    expects(:l).with(value, format: :year_month).returns('February 2024')
    @column.list_ui = :month
    assert_equal 'February 2024', get_column_value(stub(a: value), @column)

    RequestStore.clear!
    expects(:l).with(value, format: :week).returns('Week 8')
    @column.list_ui = :week
    assert_equal 'Week 8', get_column_value(stub(a: value), @column)
  end

  def test_telephone_list_ui_can_skip_number_formatting
    @column.list_ui = [:telephone, {format: false}]

    assert_dom_equal '<a href="tel:+34-555-123,9">+34 555 123 ext 9</a>',
                     get_column_value(stub(a: '+34 555 123 ext 9'), @column)
  end

  def test_inplace_edit_uses_clone_mode_for_form_override
    column = ActiveScaffold::DataStructures::Column.new(:c, ModelStub)
    column.inplace_edit = true
    stub_inplace_edit_data_dependencies
    @config.stubs(:model).returns(ModelStub)
    stubs(:inplace_edit?).with(ModelStub, column).returns(true)

    assert inplace_edit_cloning?(column)
    assert_equal :clone, inplace_edit_data(column)[:ie_mode]
    assert_dom_equal '<div style="display:none;" class="as_inplace_pattern">custom form field</div>',
                     inplace_edit_control(column)
  end

  def test_inplace_edit_uses_clone_mode_for_form_ui
    column = ActiveScaffold::DataStructures::Column.new(:d, ModelStub)
    column.form_ui = :select
    column.inplace_edit = true
    column.options[:options] = %w[first second]
    stub_inplace_edit_data_dependencies
    @config.stubs(:model).returns(ModelStub)
    stubs(:inplace_edit?).with(ModelStub, column).returns(true)

    assert inplace_edit_cloning?(column)
    assert_equal :clone, inplace_edit_data(column)[:ie_mode]
    control = Nokogiri::HTML.fragment(inplace_edit_control(column))
    assert control.at_css('div.as_inplace_pattern[style="display:none;"] select.inplace_field')
  end

  def test_ajax_inplace_edit_loads_its_field_from_render_field
    column = ActiveScaffold::DataStructures::Column.new(:d, ModelStub)
    column.inplace_edit = :ajax
    stub_inplace_edit_data_dependencies

    data = inplace_edit_data(column)

    assert_not inplace_edit_cloning?(column)
    assert_equal :ajax, data[:ie_mode]
    assert_equal '/render-field', data[:ie_render_url]
  end

  def test_string_column_inplace_edit_uses_the_default_inline_editor
    column = ActiveScaffold::DataStructures::Column.new(:d, ModelStub)
    column.inplace_edit = true
    stub_inplace_edit_data_dependencies

    data = inplace_edit_data(column)

    assert_equal :string, column.column_type
    assert_not inplace_edit_cloning?(column)
    assert_not_includes data, :ie_mode
    assert_not_includes data, :ie_render_url
  end

  def test_column_sort_value_uses_values_suitable_for_javascript_sorting
    time = Time.zone.local(2024, 2, 19, 12)

    assert_equal time.to_i, column_sort_value(stub(a: time), stub(name: :a, column: stub(type: :datetime)))
    assert_equal 1, column_sort_value(stub(a: true), stub(name: :a, column: stub(type: :boolean)))
    assert_equal 0, column_sort_value(stub(a: false), stub(name: :a, column: stub(type: :boolean)))
    assert_equal 12, column_sort_value(stub(a: 12), stub(name: :a, column: stub(type: :integer)))
    assert_equal 12, column_sort_value(stub(a: 12.0), stub(name: :a, column: stub(type: :decimal)))
    assert_equal 12.5, column_sort_value(stub(a: 12.5), stub(name: :a, column: stub(type: :decimal)))
    assert_nil column_sort_value(stub(a: 'bytes'), stub(name: :a, column: stub(type: :binary)))
    assert_equal 'Alice', column_sort_value(stub(a: 'Alice'), stub(name: :a, column: stub(type: :string)))
    assert_nil column_sort_value(stub(a: nil), stub(name: :a, column: stub(type: :string)))
  end

  private

  def grouped_search?
    false
  end

  attr_reader :search_group_function

  def stub_inplace_edit_data_dependencies
    stubs(:action_name).returns('index')
    stubs(:params_for).returns(controller: 'model_stubs')
    stubs(:url_for).returns('/render-field')
    stubs(:as_).returns('label')
  end

  def active_scaffold_config
    @config
  end
end
