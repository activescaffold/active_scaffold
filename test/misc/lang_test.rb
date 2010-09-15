require File.join(File.dirname(__FILE__), '../test_helper.rb')

class LocalizationTest < Test::Unit::TestCase

  def test_localization
    assert_equal "Dutch", as_(:dutch)
    assert_equal "dutch", as_('dutch')
    I18n.backend.store_translations :en, :active_scaffold => {:create_model => 'Create %{model}'}
    assert_equal "Create Test", as_(:create_model, :model => 'Test')
  end
end
