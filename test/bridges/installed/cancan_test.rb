# frozen_string_literal: true

require_relative 'test_helper'

class InstalledCancanBridgeTest < InstalledBridgeTestCase
  def test_cancan_bridge_aliases_actions_and_authorizes_records
    assert_installed_bridge(:cancan)

    ability = Class.new { include CanCan::Ability }.new
    ability.as_action_aliases
    ability.can :read, Project
    ability.can :update, Project
    record = Project.new
    ActiveScaffold::Registry.current_ability_proc = proc { ability }

    assert ability.can?(:list, record)
    assert ability.can?(:update_column, record)
    assert record.authorized_for?(crud_type: :update, action: :update_column)
    assert_same ability, Project.current_ability
    assert_raises ActiveScaffold::Bridges::Cancan::ActiveRecord::SecurityMethods::InvalidArgument do
      record.authorized_for?
    end
  ensure
    ActiveScaffold::Registry.current_ability_proc = nil
  end
end
