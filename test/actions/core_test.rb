# frozen_string_literal: true

require 'test_helper'

class CoreActionTest < ActiveSupport::TestCase
  test 'finds an active scaffold parent controller configured for the STI child' do
    action_class = core_action_class
    parent_model = Object.new
    child_model = stub(name: 'AdminUser', superclass: parent_model)
    parent_config = stub(add_sti_create_links?: true, sti_children: [:admin_user])
    parent_controller = stub(uses_active_scaffold?: true, active_scaffold_config: parent_config)
    action_class.stubs(:active_scaffold_config).returns(stub(model: child_model))
    action_class.expects(:active_scaffold_controller_for).with(parent_model).returns(parent_controller)

    assert_same parent_controller, action_class.new.send(:look_for_parent_sti_controller)
  end

  test 'returns nil and logs when no STI parent controller can be found' do
    action_class = core_action_class
    parent_model = Object.new
    child_model = stub(name: 'AdminUser', superclass: parent_model)
    action_class.stubs(:active_scaffold_config).returns(stub(model: child_model))
    action_class.stubs(:active_scaffold_controller_for).raises(ActiveScaffold::ControllerNotFound, 'missing controller')
    logger = mock
    logger.expects(:warn).with('missing controller looking for parent_sti of AdminUser')
    action = action_class.new
    action.stubs(:logger).returns(logger)

    assert_nil action.send(:look_for_parent_sti_controller)
  end

  private

  def core_action_class
    Class.new do
      class << self
        def before_action(...); end
        def after_action(...); end
        def around_action(...); end
        def rescue_from(...); end
        def helper_method(...); end
      end

      include ActiveScaffold::Actions::Core
    end
  end
end
