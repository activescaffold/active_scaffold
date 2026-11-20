# frozen_string_literal: true

require_relative 'test_helper'

class InstalledBitfieldsTask < Task
  include Bitfields

  bitfield :project_id, 1 => :featured, 2 => :archived
end

class InstalledBitfieldsBridgeTest < InstalledBridgeTestCase
  include ActiveScaffold::Bridges::Bitfields::ListColumnHelpers

  def test_bitfields_bridge_builds_checkbox_columns_and_formats_enabled_bits
    assert_installed_bridge(:bitfields)
    config = ActiveScaffold::Config::Core.new(:installed_bitfields_task)
    config._setup_bitfields
    record = InstalledBitfieldsTask.new(project_id: 1)
    @active_scaffold_config = config

    assert_not config.columns[:project_id].number?
    assert_equal :checkbox, config.columns[:featured].form_ui
    assert_equal :checkbox, config.columns[:archived].form_ui
    assert_operator config.columns[:archived].weight, :>, config.columns[:featured].weight
    assert record.featured?
    assert_not record.archived?
    assert_equal 'Featured', format_column_value(record, config.columns[:project_id])
  end
end
