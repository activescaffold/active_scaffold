require 'test_helper'
require File.expand_path('../../../lib/active_scaffold/bridges/paperclip/paperclip_bridge', __FILE__)
require File.expand_path('../../../lib/active_scaffold/bridges/paperclip/paperclip_bridge_helpers', __FILE__)
require File.expand_path('../../../lib/active_scaffold/bridges/paperclip/form_ui', __FILE__)
require File.expand_path('../../../lib/active_scaffold/bridges/paperclip/list_ui', __FILE__)

class PaperclipCore < ActiveScaffold::Config::Core
  include ActiveScaffold::Bridges::Paperclip::PaperclipBridge
end

class PaperclipTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ViewHelpers

  def test_initialization_without_paperclip
    Company.expects(:attachment_definitions)
    config = PaperclipCore.new(:company)
    refute config.create.multipart?
    refute config.update.multipart?
    refute config.columns.any? { |column| column.form_ui == :paperclip }
  end

  def test_initialization
    config = PaperclipCore.new(:company)
    assert config.create.multipart?
    assert config.update.multipart?
    assert_equal :paperclip, config.columns[:logo].form_ui
    assert_equal [:delete_logo], config.columns[:logo].params.to_a
    %w(logo_file_name logo_file_size logo_updated_at logo_content_type).each do |attr|
      refute config.columns._inheritable.include?(attr.to_sym)
    end
    assert Company.method_defined?(:delete_logo)
    assert Company.method_defined?(:'delete_logo=')
  end

  def test_delete
    PaperclipCore.new(:company)
    company = Company.new
    company.expects(:logo=).never
    company.delete_logo = 'false'

    company.expects(:logo).returns(stub(:dirty? => false))
    company.expects(:logo=)
    company.delete_logo = 'true' # rubocop:disable Lint/UselessSetterCall
  end

  def test_list_ui
    config = PaperclipCore.new(:company)
    company = Company.new

    company.stubs(:logo).returns(stub(:file? => true, :original_filename => 'file', :url => '/system/file', :styles => Company.attachment_definitions[:logo]))
    assert_dom_equal '<a href="/system/file" target="_blank">file</a>', active_scaffold_column_paperclip(company, config.columns[:logo])

    company.stubs(:logo).returns(stub(:file? => true, :original_filename => 'file', :url => '/system/file', :styles => {:thumbnail => '40x40'}))
    assert_dom_equal '<a href="/system/file" target="_blank"><img src="/system/file" border="0" alt="File"/></a>', active_scaffold_column_paperclip(company, config.columns[:logo])
  end

  def test_form_ui
    js, ActiveScaffold.js_framework = ActiveScaffold.js_framework, :jquery
    config = PaperclipCore.new(:company)
    @record = Company.new

    @record.stubs(:logo).returns(stub(:file? => true, :original_filename => 'file', :url => '/system/file', :styles => Company.attachment_definitions[:logo]))
    escaped_quote = Rails::VERSION::MAJOR < 4 ? '&#x27;' : '&#39;'
    assert_dom_equal %{<div><a href="/system/file" target="_blank">file</a> | <input name="record[delete_logo]" type="hidden" id="record_delete_logo" value="false" /><a href="#" onclick="jQuery(this).prev().val(#{escaped_quote}true#{escaped_quote}); jQuery(this).parent().hide().next().show(); return false;">Remove or Replace file</a></div><div style="display: none"><input name="record[logo]" class="text-input" autocomplete="off" type="file" id="record_logo" /></div>}, active_scaffold_input_paperclip(config.columns[:logo], :name => 'record[logo]', :id => 'record_logo', :object => @record)

    @record.stubs(:logo).returns(stub(:file? => false))
    assert_dom_equal '<input name="record[logo]" class="text-input" autocomplete="off" type="file" id="record_logo" />', active_scaffold_input_paperclip(config.columns[:logo], :name => 'record[logo]', :id => 'record_logo', :object => @record)
    ActiveScaffold.js_framework = js
  end
end
