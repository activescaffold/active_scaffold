# frozen_string_literal: true

require_relative 'test_helper'

class InstalledCountrySelectBridgeTest < InstalledBridgeTestCase
  include ActiveScaffold::Bridges::CountrySelect::FormColumnHelpers
  include ActiveScaffold::Bridges::CountrySelect::ListColumnHelpers
  include ActiveScaffold::Bridges::CountrySelect::SearchColumnHelpers

  def test_country_select_bridge_uses_the_real_country_data
    assert_installed_bridge(:country_select)
    record = Struct.new(:country).new('US')
    column = Struct.new(:name, :options).new(:country, {})

    assert_method_installed :active_scaffold_column_country
    assert_equal 'United States', active_scaffold_column_country(record, column)
    record.country = 'not-a-country'
    assert_equal 'not-a-country', active_scaffold_column_country(record, column)
    record.country = nil
    assert_nil active_scaffold_column_country(record, column)
    assert CountrySelect::FORMATS.key?(:old)

    record.country = 'US'
    html = active_scaffold_input_country(
      column,
      {name: 'record[country]', id: 'record_country', object: record},
      ui_options: {priority: [:us]}
    )
    assert_includes html, '<select'
    assert_includes html, 'value="US"'
  end

  private

  def assert_method_installed(method_name)
    assert ActionView::Base.method_defined?(method_name), "#{method_name} was not installed on ActionView::Base"
  end
end
