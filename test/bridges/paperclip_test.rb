require 'test/unit'
require File.join(File.dirname(__FILE__), 'company')
require File.join(File.dirname(__FILE__), '../../lib/bridges/paperclip/lib/paperclip_bridge')
require File.join(File.dirname(__FILE__), '../../lib/bridges/paperclip/lib/paperclip_bridge_helpers')
require File.join(File.dirname(__FILE__), '../../lib/bridges/paperclip/lib/form_ui')
require File.join(File.dirname(__FILE__), '../../lib/bridges/paperclip/lib/list_ui')

class PaperclipCore < ActiveScaffold::Config::Core
  include ActiveScaffold::PaperclipBridge
end

class PaperclipTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ViewHelpers

  def test_initialization_without_paperclip
    Company.expects(:attachment_definitions)
    config = PaperclipCore.new(:company)
    assert !config.create.multipart?
    assert !config.update.multipart?
    assert !config.columns.any? {|column| column.form_ui == :paperclip}
  end

  def test_initialization
    config = PaperclipCore.new(:company)
    assert config.create.multipart?
    assert config.update.multipart?
    assert_equal :paperclip, config.columns[:logo].form_ui
    assert_equal [:delete_logo], config.columns[:logo].params.to_a
    %w(logo_file_name logo_file_size logo_updated_at logo_content_type).each do |attr|
      assert !config.columns._inheritable.include?(attr.to_sym)
    end
    assert Company.instance_methods.include?('delete_logo')
    assert Company.instance_methods.include?('delete_logo=')
  end

  def test_delete
    PaperclipCore.new(:company)
    company = Company.new
    company.expects(:logo=).never
    company.delete_logo = 'false'

    company.expects(:logo).returns(stub(:dirty? => false))
    company.expects(:logo=)
    company.delete_logo = 'true'
  end

  def test_list_ui
    config = PaperclipCore.new(:company)
    company = Company.new

    company.stubs(:logo).returns(stub(:file? => true, :original_filename => 'file', :url => '/system/file', :styles => Company.attachment_definitions[:logo]))
    assert_dom_equal '<a href="/system/file" onclick="window.open(this.href);return false;">file</a>', active_scaffold_column_paperclip(config.columns[:logo], company)

    company.stubs(:logo).returns(stub(:file? => true, :original_filename => 'file', :url => '/system/file', :styles => {:thumbnail => '40x40'}))
    assert_dom_equal '<a href="/system/file" onclick="window.open(this.href);return false;"><img src="/system/file" border="0" alt="File"/></a>', active_scaffold_column_paperclip(config.columns[:logo], company)
  end

  def test_form_ui
    config = PaperclipCore.new(:company)
    @record = Company.new

    @record.stubs(:logo).returns(stub(:file? => true, :original_filename => 'file', :url => '/system/file', :styles => Company.attachment_definitions[:logo]))
    assert_dom_equal '<div><a href="/system/file" onclick="window.open(this.href);return false;">file</a>|<a href="#" onclick="$(this).next().value=\'true\'; $(this).up().hide().next().show(); return false;">Remove or Replace file</a><input name="record[delete_logo]" type="hidden" id="record_delete_logo" value="false" /></div><div style="display: none"><input name="record[logo]" size="30" type="file" id="record_logo" /></div>', active_scaffold_input_paperclip(config.columns[:logo], :name => 'record[logo]', :id => 'record_logo')

    @record.stubs(:logo).returns(stub(:file? => false))
    assert_dom_equal '<input name="record[logo]" size="30" type="file" id="record_logo" />', active_scaffold_input_paperclip(config.columns[:logo], :name => 'record[logo]', :id => 'record_logo')
  end
end
