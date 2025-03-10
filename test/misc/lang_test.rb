require 'test_helper'

class LocalizationTest < ActiveSupport::TestCase
  def test_localization
    assert_equal 'Dutch', as_(:dutch)
    assert_equal 'dutch', as_('dutch')
    I18n.backend.store_translations :en, active_scaffold: {create_model: 'Create %<model>s'}
    assert_equal 'Create Test', as_(:create_model, model: 'Test')
  end
end
