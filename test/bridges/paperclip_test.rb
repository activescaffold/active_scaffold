# frozen_string_literal: true

require 'test_helper'
require File.expand_path('../../lib/active_scaffold/bridges/paperclip/paperclip_bridge', __dir__)
require File.expand_path('../../lib/active_scaffold/bridges/paperclip/paperclip_bridge_helpers', __dir__)
require File.expand_path('../../lib/active_scaffold/bridges/paperclip/form_ui', __dir__)
require File.expand_path('../../lib/active_scaffold/bridges/paperclip/list_ui', __dir__)

class PaperclipCore < ActiveScaffold::Config::Core
  include ActiveScaffold::Bridges::Paperclip::PaperclipBridge
end

class PaperclipTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ViewHelpers

  def test_initialization_without_paperclip
    Company.expects(:attachment_definitions)
    config = PaperclipCore.new(:company)
    assert_not config.create.multipart?
    assert_not config.update.multipart?
    assert_not(config.columns.any? { |column| column.form_ui == :paperclip })
  end

  def test_initialization
    config = PaperclipCore.new(:company)
    assert config.create.multipart?
    assert config.update.multipart?
    assert_equal :paperclip, config.columns[:logo].form_ui
    assert_equal [:delete_logo], config.columns[:logo].params.to_a
    %w[logo_file_name logo_file_size logo_updated_at logo_content_type].each do |attr|
      assert_not config.columns._inheritable.include?(attr.to_sym)
    end
    assert Company.method_defined?(:delete_logo)
    assert Company.method_defined?(:'delete_logo=')
  end

  def test_delete
    PaperclipCore.new(:company)
    company = Company.new
    company.expects(:logo=).never
    company.delete_logo = 'false'

    company.expects(:logo).returns(stub(dirty?: false))
    company.expects(:logo=)
    company.delete_logo = 'true' # rubocop:disable Lint/UselessSetterCall
  end

  def test_list_ui
    config = PaperclipCore.new(:company)
    company = Company.new

    company.stubs(:logo).returns(stub(file?: true, original_filename: 'file', url: '/system/file', styles: Company.attachment_definitions[:logo]))
    assert_dom_equal '<a href="/system/file" rel="noopener" target="_blank">file</a>', active_scaffold_column_paperclip(company, config.columns[:logo])

    company.stubs(:logo).returns(stub(file?: true, original_filename: 'file', url: '/system/file', styles: {thumbnail: '40x40'}))
    assert_dom_equal '<a href="/system/file" rel="noopener" target="_blank"><img src="/system/file" border="0"/></a>', active_scaffold_column_paperclip(company, config.columns[:logo])
  end

  def test_form_ui
    config = PaperclipCore.new(:company)
    @record = Company.new
    opts = {name: 'record[logo]', id: 'record_logo', object: @record}

    @record.stubs(:logo).returns(stub(file?: true, original_filename: 'file', url: '/system/file', styles: Company.attachment_definitions[:logo]))
    click_js = "jQuery(this).prev().val('true'); jQuery(this).parent().hide().next().show(); return false;"
    change_js = "jQuery(this).parents('div.paperclip_controls').find('input.remove_file').val('false'); return false;"
    @document = Nokogiri::HTML::Document.parse(active_scaffold_input_paperclip(config.columns[:logo], opts))
    assert_select 'div.paperclip_controls input[type=file]' do |match|
      assert_equal match[0]['onchange'], change_js
    end
    assert_select 'div.paperclip_controls a[href="#"][onclick]' do |match|
      assert_equal match[0]['onclick'], click_js
    end
    assert_select 'div.paperclip_controls input.remove_file[type=hidden][value=false]'

    @record.stubs(:logo).returns(stub(file?: false))
    assert_dom_equal '<input name="record[logo]" class="text-input" autocomplete="off" type="file" id="record_logo" />', active_scaffold_input_paperclip(config.columns[:logo], opts)
  end

  protected

  def document_root_element
    @document.root
  end
end
