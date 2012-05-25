require 'test/unit'
require File.join(File.dirname(__FILE__), 'company')
require File.join(File.dirname(__FILE__), '../../lib/bridges/tiny_mce/lib/tiny_mce_bridge')

class TinyMceTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ViewHelpers
  include ActiveScaffold::TinyMceBridge

  def test_includes
    assert_match /.*<script type="text\/javascript">.*ActiveScaffold\.ActionLink\.Abstract\.prototype\.close = function\(\).*<\/script>.*/m, active_scaffold_includes
  end

  def test_form_ui
    config = PaperclipCore.new(:company)
    @record = Company.new
    self.expects(:request).returns(stub(:xhr? => true))

    assert_dom_equal "<textarea name=\"record[name]\" class=\"name-input mceEditor\" id=\"record_name\"></textarea><script type=\"text/javascript\">\n//<![CDATA[\ntinyMCE.execCommand('mceAddControl', false, 'record_name');\n//]]>\n</script>", active_scaffold_input_text_editor(config.columns[:name], :name => 'record[name]', :id => 'record_name', :class => 'name-input')
  end

  protected
  def include_tiny_mce_if_needed; end
  def tiny_mce_js; end
  def using_tiny_mce?
    true
  end
end
