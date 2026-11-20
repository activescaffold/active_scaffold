# frozen_string_literal: true

require_relative 'test_helper'

class InstalledAncestryProject < Project
  has_ancestry
end

class InstalledAncestryBridgeTest < InstalledBridgeTestCase
  include ActiveScaffold::Bridges::Ancestry::FormColumnHelpers

  def test_ancestry_bridge_configures_columns_and_renders_the_tree
    assert_installed_bridge(:ancestry)
    config = ActiveScaffold::Config::Core.new(:installed_ancestry_project)
    root = InstalledAncestryProject.new(name: 'Root')
    child = InstalledAncestryProject.new(name: 'Child', ancestry: '1')
    record = InstalledAncestryProject.new(name: 'Current', ancestry: '1/2')
    root.id = 1
    child.id = 2
    record.id = 3
    InstalledAncestryProject.stubs(:arrange).returns(root => {child => {}})

    assert_equal :ancestry, config.columns[:parent_id].form_ui
    assert_not_includes config.create.columns, :parent_id
    assert_includes config.update.columns, :parent_id

    html = active_scaffold_input_ancestry(
      config.columns[:parent_id],
      {name: 'record[parent_id]', id: 'record_parent_id', object: record}
    )
    assert_includes html, '>Root</option>'
    assert_includes html, '>__Child</option>'
    assert_includes html, 'selected="selected" value="2"'
  end
end
