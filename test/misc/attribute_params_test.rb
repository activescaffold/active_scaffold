require 'test_helper'

class Controller
  def self.helper_method(*args); end
  include ActiveScaffold::Helpers::ControllerHelpers
  include ActiveScaffold::AttributeParams
  public :update_record_from_params
end

class AttributeParamsTest < Test::Unit::TestCase
  def setup
    @controller = Controller.new
  end

  def test_saving_simple_record
    #assert @controller.update_record_from_params(Person.new, [], {})
  end
end
