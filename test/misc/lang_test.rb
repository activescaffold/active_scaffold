require File.join(File.dirname(__FILE__), '../test_helper.rb')

class LocalizationTest < Test::Unit::TestCase

  def test_localization
    ##
    ## test no language specified
    ##
    assert_equal "dutch", _("dutch")
    assert_equal "Create", _("CREATE")
    ActiveScaffold::Config::Core.configure do |c| 
      c.lang = "nl_NL" 
    end
    ##
    ## test language specified
    ##
    assert_equal "Toevoegen", _("CREATE")
  end
end