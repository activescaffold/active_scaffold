# frozen_string_literal: true

require 'test_helper'

class FormUiHelpersTest < ActionView::TestCase # rubocop:disable Metrics/ClassLength
  include ActiveScaffold::Helpers::FormColumnHelpers
  include ActiveScaffold::Helpers::ViewHelpers

  def setup
    @column = ActiveScaffold::DataStructures::Column.new(:a, ModelStub)
    @record = ModelStub.new(a: nil)
  end

  def test_file_input_without_content_renders_a_visible_file_field
    html = active_scaffold_file_with_content(
      @column,
      {object: @record, name: 'record[a]', id: 'record_a'},
      nil,
      'remove_',
      'file-controls'
    )
    input = Nokogiri::HTML.fragment(html).at_css('input[type="file"]')

    assert_equal 'record[a]', input['name']
    assert_equal 'record_a', input['id']
    assert_nil input['style']
  end

  def test_file_input_with_content_renders_remove_control_and_replacement_field
    html = active_scaffold_file_with_content(
      @column,
      {object: @record, name: 'record[a]', id: 'record_a', required: true},
      content_tag(:span, 'avatar.png'),
      'remove_',
      'file-controls'
    ) { content_tag(:em, '1 KB') }
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css('div.file-controls.file-input-controls[data-required="true"]')
    assert_equal 'avatar.png | 1 KBRemove or replace file', fragment.at_css('div > div').text
    assert_equal '#', fragment.at_css('a.remove-file-btn')['href']
    assert_equal 'record[remove_a]', fragment.at_css('input.remove_file')['name']
    assert_equal 'false', fragment.at_css('input.remove_file')['value']
    assert_equal 'display: none', fragment.at_css('input[type="file"]')['style']
  end

  def test_remove_file_link_uses_plural_translation_for_multiple_input
    html = active_scaffold_file_with_remove_link(
      'Existing files', {multiple: true}, 'attachments'
    )

    assert_includes Nokogiri::HTML.fragment(html).text, 'Remove or add files'
  end

  def test_checkbox_list_for_enum_checks_selected_values_and_supports_draggable_lists
    @record.a = ['second']
    ui_options = {
      options: [%w[First first], %w[Second second]],
      draggable_lists: true,
      item_options: {class: 'choice'}
    }
    html = active_scaffold_input_checkboxes(
      @column,
      {object: @record, name: 'record[a]', id: 'record_a', class: 'a-input'},
      ui_options: ui_options
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css('.check-all')
    assert fragment.at_css('.uncheck-all')
    assert fragment.at_css('ul.checkbox-list.draggable-lists')
    assert_equal 2, fragment.css('li.choice').size
    assert fragment.at_css('input[value="second"][checked="checked"]')
    assert_nil fragment.at_css('input[value="first"]')['checked']
    assert fragment.at_css('input[type="hidden"][name="record[a][]"]')
  end

  def test_checkboxes_reject_singular_associations_and_non_array_values
    singular_column = ActiveScaffold::DataStructures::Column.new(:category, Task)
    error = assert_raises(ArgumentError) do
      active_scaffold_input_checkboxes(singular_column, {object: Task.new})
    end
    assert_match(/expects a collection/, error.message)

    @record.a = 'not an array'
    error = assert_raises(ArgumentError) do
      active_scaffold_input_checkboxes(@column, {object: @record})
    end
    assert_match(/getter to return an Array/, error.message)
  end

  def test_plural_association_without_options_renders_message_and_empty_value
    column = ActiveScaffold::DataStructures::Column.new(:roles, Person)
    record = Person.new
    stubs(:association_helper_method).returns(:available_roles)
    stubs(:available_roles).with(column.association, nil, record).returns([])

    html = active_scaffold_input_plural_association(
      column,
      {object: record, name: 'record[roles]', id: 'record_roles', class: 'roles-input'}
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css('span.roles-input.no-options')
    assert_includes fragment.text, 'No options'
    assert fragment.at_css('input[type="hidden"][name="record[roles][]"]')
  end

  def test_plural_association_multiple_select_adds_array_suffix_once
    column = ActiveScaffold::DataStructures::Column.new(:roles, Person)
    selected = Role.new(id: 1, name: 'Editor')
    available = Role.new(id: 2, name: 'Reviewer')
    record = Person.new
    record.roles = [selected]
    stubs(:association_helper_method).returns(:available_roles)
    stubs(:available_roles).with(column.association, nil, record).returns([available])

    html = active_scaffold_input_plural_association(
      column,
      {object: record, name: 'record[roles][]', id: 'record_roles', multiple: true}
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal 'record[roles][]', fragment.at_css('select')['name']
    assert_equal %w[1 2], fragment.css('option').pluck('value')
  end

  def test_singular_association_renders_optgroups_and_refresh_link
    column = ActiveScaffold::DataStructures::Column.new(:category, Task)
    first = Category.new(id: 1, name: 'First', created_at: Time.utc(2026, 1, 1))
    second = Category.new(id: 2, name: 'Second', created_at: Time.utc(2026, 2, 1))
    record = Task.new(category: first)
    stubs(:association_helper_method).returns(:available_categories)
    stubs(:available_categories).with(column.association, nil, record).returns([first, second])
    stubs(:active_scaffold_refresh_link).returns(
      content_tag(:a, 'Refresh categories', class: 'refresh-link')
    )

    html = active_scaffold_input_singular_association(
      column,
      {object: record, name: 'record[category]', id: 'record_category', associated: second.id},
      ui_options: {optgroup: :created_at, label_method: :name, refresh_link: true}
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal [first.created_at.to_s, second.created_at.to_s], fragment.css('optgroup').pluck('label')
    assert_equal %w[First Second], fragment.css('optgroup option').map(&:text)
    assert_equal second.id.to_s, fragment.at_css('option[selected="selected"]')['value']
    assert_equal 'Refresh categories', fragment.at_css('a.refresh-link').text
  end

  def test_collection_checkboxes_and_draggable_input_delegate_to_plural_renderer
    column = ActiveScaffold::DataStructures::Column.new(:roles, Person)
    options = {object: Person.new, name: 'record[roles]', id: 'record_roles'}
    expects(:active_scaffold_input_plural_association).with(
      column, options, ui_options: column.options
    ).returns('checkboxes')

    assert_equal 'checkboxes', active_scaffold_input_checkboxes(column, options)

    expects(:active_scaffold_input_checkboxes).with(
      @column, options.merge(draggable_lists: true), ui_options: @column.options
    ).returns('draggable')
    assert_equal 'draggable', active_scaffold_input_draggable(@column, options)
  end

  def test_enum_radio_buttons_render_blank_option_and_selected_value
    @record.a = 'second'
    ui_options = {
      options: [%w[First first], %w[Second second]],
      include_blank: :_select_
    }
    html = active_scaffold_input_radio(
      @column,
      {object: @record, name: 'record[a]', id: 'record_a', class: 'a-input'},
      ui_options: ui_options
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal 3, fragment.css('input[type="radio"]').size
    assert_equal '', fragment.css('input[type="radio"]').first['value']
    assert_equal 'second', fragment.at_css('input[checked="checked"]')['value']
    assert_includes fragment.text, '- select -'
  end

  def test_association_radio_buttons_use_label_method_and_selected_record
    column = ActiveScaffold::DataStructures::Column.new(:category, Task)
    selected = Category.new(id: 1, name: 'Selected')
    available = Category.new(id: 2, name: 'Available')
    record = Task.new(category: selected)
    stubs(:association_helper_method).returns(:available_categories)
    stubs(:available_categories).with(column.association, nil, record).returns([selected, available])

    html = active_scaffold_input_radio(
      column,
      {object: record, name: 'record[category]', id: 'record_category', class: 'category-input'},
      ui_options: {label_method: :name}
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal %w[Selected Available], fragment.css('label').map(&:text)
    assert_equal '1', fragment.at_css('input[checked="checked"]')['value']
    assert_equal %w[record_category-1 record_category-2], fragment.css('input').pluck('id')
  end

  def test_radio_appends_refresh_link_with_radio_group_selector
    stubs(:active_scaffold_refresh_link).with do |column, html_options, record, ui_options|
      column == @column && record == @record && html_options[:name] == 'record[a]' &&
        ui_options[:field_selector] == '[name="record[a]"]'
    end.returns(content_tag(:a, 'Refresh choices', class: 'refresh-link'))

    html = active_scaffold_input_radio(
      @column,
      {object: @record, name: 'record[a]', id: 'record_a'},
      ui_options: {options: [%w[First first]], refresh_link: true}
    )

    assert_includes html, 'Refresh choices'
  end

  def test_radio_without_options_renders_no_options_and_hidden_value
    html = active_scaffold_input_radio(
      @column,
      {object: @record, name: 'record[a]', id: 'record_a', class: 'a-input'},
      ui_options: {options: []}
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css('span.a-input.no-options')
    assert fragment.at_css('input[type="hidden"][name="record[a]"][id="record_a"]')
  end

  def test_radio_without_options_wraps_add_new_control
    stubs(:active_scaffold_add_new).returns(content_tag(:a, 'Create option', href: '/new'))

    html = active_scaffold_input_radio(
      @column,
      {object: @record, name: 'record[a]', id: 'record_a', class: 'a-input'},
      ui_options: {options: [], add_new: {mode: :popup}}
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css('div.select-field span.no-options')
    assert_equal '/new', fragment.at_css('a')['href']
  end

  def test_radio_add_new_subform_renders_create_new_choice
    html_options = {object: @record, name: 'record[a]', id: 'record_a', class: 'a-input'}
    stubs(:active_scaffold_subform_attributes).returns(id: 'new_a_subform')
    expects(:active_scaffold_add_new).with(
      @column, @record, html_options, ui_options: {add_new: true}, skip_link: true
    ).returns(content_tag(:div, 'Subform', id: 'new_a_subform'))

    html = active_scaffold_input_radio_content(
      @column, @record, [%w[First first]], html_options, {add_new: true}
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css('input.a-input.hide-new-subform[data-subform-id="new_a_subform"]')
    assert fragment.at_css('input.show-new-subform[id="record_a-create_new"]')
    assert_includes fragment.text, 'Create new'
    assert fragment.at_css('div#new_a_subform')
  end

  def test_radio_add_new_popup_passes_parent_scope_and_update_data
    html_options = {
      object: @record,
      name: 'record[children][0][a]',
      id: 'record_children_0_a',
      class: 'a-input',
      'data-update_url' => '/records/render_field'
    }
    add_new_options = {mode: :popup}
    expects(:active_scaffold_add_new).with do |column, record, received_options, ui_options:, skip_link:|
      popup_options = ui_options[:add_new]
      column == @column && record == @record && received_options == html_options && !skip_link &&
        popup_options.dig(:url_options, :parent_scope) == '[children][0]' &&
        popup_options.dig(:url_options, :radio_data, 'data-update_url') == '/records/render_field'
    end.returns(content_tag(:a, 'New', href: '/new'))

    html = active_scaffold_input_radio_content(
      @column, @record, [%w[First first]], html_options, {add_new: add_new_options}
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css('span.new-radio-container#record_children_0_a')
    assert_equal '/new', fragment.at_css('a')['href']
  end

  def test_textual_input_helpers_render_their_html5_types
    options = {object: @record, name: 'record[a]', id: 'record_a'}
    {
      active_scaffold_input_email: 'email',
      active_scaffold_input_url: 'url',
      active_scaffold_input_telephone: 'tel',
      active_scaffold_input_date: 'date',
      active_scaffold_input_time: 'time',
      active_scaffold_input_datetime: 'datetime-local',
      active_scaffold_input_month: 'month',
      active_scaffold_input_week: 'week'
    }.each do |helper, type|
      input = Nokogiri::HTML.fragment(send(helper, @column, options.dup)).at_css('input')

      assert_equal type, input['type'], helper.to_s
      assert_includes input['class'], 'text-input', helper.to_s
      assert_equal 'off', input['autocomplete'], helper.to_s
    end
  end

  def test_virtual_number_range_and_non_nullable_color_inputs
    options = {object: @record, name: 'record[a]', id: 'record_a'}

    assert_equal 'text', Nokogiri::HTML.fragment(
      active_scaffold_input_virtual(@column, options.dup)
    ).at_css('input')['type']
    assert_equal 'number', Nokogiri::HTML.fragment(
      active_scaffold_input_number(@column, options.dup)
    ).at_css('input')['type']
    assert_equal 'range', Nokogiri::HTML.fragment(
      active_scaffold_input_range(@column, options.dup)
    ).at_css('input')['type']

    @column.stubs(:null?).returns(false)
    color = Nokogiri::HTML.fragment(active_scaffold_input_color(@column, options.dup))
    assert color.at_css('input[type="color"]')
    assert_nil color.at_css('input.no-color')
  end

  def test_select_with_add_new_wraps_input_and_control
    stubs(:active_scaffold_add_new).returns(content_tag(:a, 'Create option', href: '/new'))
    ui_options = {options: [%w[First first]], add_new: {mode: :popup}}

    html = active_scaffold_input_select(
      @column,
      {object: @record, name: 'record[a]', id: 'record_a'},
      ui_options: ui_options
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert fragment.at_css('div.select-field select')
    assert_equal '/new', fragment.at_css('a')['href']
  end

  def test_password_textarea_checkbox_and_multiple_select_helpers
    password = Nokogiri::HTML.fragment(
      active_scaffold_input_password(@column, {object: @record, name: 'record[a]', id: 'record_a'})
    ).at_css('input')
    assert_equal 'password', password['type']
    assert_equal 'new-password', password['autocomplete']

    textarea = Nokogiri::HTML.fragment(
      active_scaffold_input_textarea(
        @column,
        {object: @record, name: 'record[a]', id: 'record_a'},
        ui_options: {rows: 4, cols: 20}
      )
    ).at_css('textarea')
    assert_equal '4', textarea['rows']
    assert_equal '20', textarea['cols']

    checkbox = Nokogiri::HTML.fragment(
      active_scaffold_input_checkbox(@column, {object: @record, name: 'record[a]', id: 'record_a'})
    )
    assert checkbox.at_css('input[type="checkbox"]')
    assert checkbox.at_css('input[type="hidden"]')

    @column.options[:options] = [%w[First first]]
    select = Nokogiri::HTML.fragment(
      active_scaffold_input_select_multiple(
        @column, {object: @record, name: 'record[a]', id: 'record_a'}
      )
    ).at_css('select')
    assert_equal 'multiple', select['multiple']
    assert_equal 'record[a][]', select['name']
  end

  def test_nullable_color_input_can_be_disabled
    @column.stubs(:null?).returns(true)
    options = {object: @record, name: 'record[a]', id: 'record_a'}
    fragment = Nokogiri::HTML.fragment(active_scaffold_input_color(@column, options))

    assert fragment.at_css('input.no-color[checked="checked"]')
    assert fragment.at_css('input[type="hidden"][name="record[a]"]')
    assert_includes fragment.text, 'No color'

    @record.a = '#123456'
    fragment = Nokogiri::HTML.fragment(active_scaffold_input_color(@column, options))

    assert_nil fragment.at_css('input.no-color')['checked']
    assert_equal '#123456', fragment.at_css('input[type="color"]')['value']
  end

  def test_nullable_boolean_input_includes_translated_blank_option
    @column.stubs(:null?).returns(true)
    html = active_scaffold_input_boolean(
      @column,
      {object: @record, name: 'record[a]', id: 'record_a'}
    )
    fragment = Nokogiri::HTML.fragment(html)

    assert_equal ['', 'true', 'false'], fragment.css('option').pluck('value')
    assert_equal '- select -', fragment.css('option').first.text
  end

  def test_select_option_symbols_and_multiple_names_are_normalized
    options = {include_blank: :_select_, prompt: :refresh}

    assert_same options, active_scaffold_translate_select_options(options)
    assert_equal '- select -', options[:include_blank]
    assert_equal 'Refresh', options[:prompt]

    html_options = {multiple: true, name: 'record[a]'}
    active_scaffold_select_name_with_multiple(html_options)
    active_scaffold_select_name_with_multiple(html_options)
    assert_equal 'record[a][]', html_options[:name]
  end

  def test_add_new_rejects_an_unsupported_mode
    column = ActiveScaffold::DataStructures::Column.new(:category, Task)

    error = assert_raises(ArgumentError) do
      active_scaffold_add_new(
        column,
        Task.new,
        {name: 'record[category]', id: 'record_category'},
        ui_options: {add_new: {mode: :drawer}}
      )
    end

    assert_equal 'unsupported mode for add_new: :drawer', error.message
  end

  def test_add_new_popup_renders_link_with_parent_context
    column = ActiveScaffold::DataStructures::Column.new(:category, Task)
    record = Task.new(id: 12)
    stubs(:active_scaffold_controller_for).with(Category).returns(stub(controller_path: 'categories'))

    html = active_scaffold_add_new(
      column,
      record,
      {name: 'record[category]', id: 'record_category'},
      ui_options: {add_new: {mode: :popup, add_new_text: 'Create category'}}
    )
    link = Nokogiri::HTML.fragment(html).at_css('a')

    assert_equal 'Create category', link.text
    assert_includes link['class'], 'as_action'
    assert_equal 'popup', link['data-position']
    assert_includes link['href'], '/categories/new'
    assert_includes link['href'], 'from_field=record_category'
    assert_includes link['href'], 'parent_model=Task'
    assert_includes link['href'], 'parent_column=category'
    assert_includes link['href'], 'embedded%5Bconstraints%5D%5Btasks%5D%5B%5D=12'
  end

  def test_add_new_subform_renders_new_record_and_toggle_link
    column = ActiveScaffold::DataStructures::Column.new(:category, Task)
    record = Task.new
    html_options = {
      name: 'record[children][0][category]',
      id: 'record_children_0_category'
    }
    stubs(:active_scaffold_subform_attributes).returns(
      class: +'sub-form vertical-sub-form category-sub-form',
      id: 'category-subform'
    )
    stubs(:subform_partial_for_column).returns('vertical_subform')
    stubs(:generated_id).with(record).returns(23)
    expects(:sub_form_id).with(association: :category, id: 23).returns('category-subform')
    expects(:link_to_visibility_toggle).with(
      'category-subform-div', default_visible: false
    ).returns(content_tag(:a, 'Show fields', class: 'visibility-toggle'))
    expects(:render).with do |partial:, locals:|
      partial == 'vertical_subform' && locals[:column] == column && locals[:parent_record] == record &&
        locals[:associated] == [] && locals[:show_blank_record].is_a?(Category) &&
        locals[:scope] == '[children][0]'
    end.returns(content_tag(:span, 'New category fields', class: 'new-category-fields'))

    html = active_scaffold_add_new(
      column,
      record,
      html_options,
      ui_options: {
        add_new: {
          mode: :subform,
          add_new_text: 'Build category',
          add_existing_text: 'Choose category',
          hide_subgroups: true
        }
      }
    )
    fragment = Nokogiri::HTML.fragment(html)
    subform = fragment.at_css('div#category-subform')
    link = fragment.at_css('a.show-new-subform')

    assert_includes subform['class'], 'optional'
    assert_equal 'display: none', subform['style']
    assert_equal 'New category fields', subform.at_css('.new-category-fields').text
    assert_equal 'Show fields', subform.at_css('.visibility-toggle').text
    assert_equal 'Build category', link.text
    assert_equal 'record_children_0_category', link['data-select-id']
    assert_equal 'category-subform', link['data-subform-id']
    assert_equal 'Choose category', link['data-subform-text']
    assert_equal 'Build category', link['data-select-text']
  end

  def test_polymorphic_new_record_class_respects_the_type_allowlist
    column = ActiveScaffold::DataStructures::Column.new(:contactable, Contact)
    record = Contact.new(contactable_type: 'Person')

    assert_equal Person, active_scaffold_new_record_klass(column, record)
    assert_equal Person, active_scaffold_new_record_klass(column, record, types: ['Person'])
    assert_nil active_scaffold_new_record_klass(column, record, types: ['Project'])

    record.contactable_type = nil
    assert_nil active_scaffold_new_record_klass(column, record)
  end

  def test_non_polymorphic_new_record_class_is_association_class
    column = ActiveScaffold::DataStructures::Column.new(:category, Task)

    assert_equal Category, active_scaffold_new_record_klass(column, Task.new)
  end

  def test_popup_url_constraints_use_reverse_association
    column = ActiveScaffold::DataStructures::Column.new(:category, Task)
    record = Task.new(id: 12)

    assert_equal(
      {embedded: {constraints: {tasks: [12]}}},
      active_scaffold_new_record_url_options(column, record)
    )

    association = stub(reverse: nil, klass: Category)
    column = stub(name: :category, association: association)
    error = assert_raises(RuntimeError) do
      active_scaffold_new_record_url_options(column, record)
    end
    assert_match(/no reverse association/, error.message)
  end

  def test_show_new_subform_link_uses_custom_labels_and_current_state
    column = ActiveScaffold::DataStructures::Column.new(:category, Task)
    record = Task.new(category: Category.new)
    html = active_scaffold_show_new_subform_link(
      column,
      record,
      'record_category',
      'category_subform',
      options: {add_existing_text: 'Choose existing', add_new_text: 'Build category'}
    )
    link = Nokogiri::HTML.fragment(html).at_css('a')

    assert_equal 'Choose existing', link.text
    assert_equal 'record_category', link['data-select-id']
    assert_equal 'category_subform', link['data-subform-id']
    assert_equal 'Choose existing', link['data-subform-text']
    assert_equal 'Build category', link['data-select-text']
  end

  def test_refresh_link_uses_existing_update_url_and_custom_options
    html = active_scaffold_refresh_link(
      @column,
      {
        id: 'record_a',
        'data-update_url' => '/records/render_field',
        'data-update_send_form' => true,
        'data-update_send_form_selector' => '#record'
      },
      @record,
      refresh_link: {text: 'Reload', title: 'Reload choices'}
    )
    link = Nokogiri::HTML.fragment(html).at_css('a')

    assert_equal 'Reload', link.text
    assert_equal '/records/render_field', link['href']
    assert_equal 'refresh-link', link['class']
    assert_equal 'Reload choices', link['title']
    assert_equal '#record_a', link['data-field-selector']
    assert_equal 'true', link['data-update_send_form']
    assert_equal '#record', link['data-update_send_form_selector']
  end

  def test_refresh_link_builds_update_url_from_nested_scope
    expects(:update_columns_options).with do |column, scope, options, force:|
      column == @column && scope == '[children][0]' && force && options[:object] == @record
    end.returns(
      data: {field_selector: '#record_children_0_a'},
      'data-update_url' => '/records/render_field'
    )

    html = active_scaffold_refresh_link(
      @column,
      {name: 'record[children][0][a]', id: 'record_children_0_a'},
      @record
    )
    link = Nokogiri::HTML.fragment(html).at_css('a')

    assert_equal '/records/render_field', link['href']
    assert_equal '#record_children_0_a', link['data-field-selector']
  end

  private

  def active_scaffold_config
    @active_scaffold_config ||= stub(cache_association_options: false)
  end

  def active_scaffold_config_for(klass)
    @active_scaffold_configs ||= {}
    @active_scaffold_configs[klass] ||= config_for(klass)
  end
end
