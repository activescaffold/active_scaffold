# frozen_string_literal: true

require 'test_helper'
require 'active_scaffold_config_mock'
require File.expand_path('../../lib/active_scaffold/bridges/date_picker/ext', __dir__)

class DatePickerTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ViewHelpers
  include ActiveScaffold::Bridges::DatePicker::Helper::FormColumnHelpers
  include ActiveScaffold::Bridges::DatePicker::Helper::DatepickerColumnHelpers

  def setup
    @controller.class.class_eval do
      include ActiveScaffoldConfigMock
      include ActiveScaffold::Finder
    end
  end

  def test_set_form_ui
    config = ActiveScaffold::Config::Core.new(:company)
    assert_nil config.columns[:name].form_ui, 'form_ui for name'
    assert_equal :date_picker, config.columns[:date].form_ui, 'form_ui for date'
    assert_equal :datetime_picker, config.columns[:datetime].form_ui, 'form_ui for datetime'
  end

  def test_form_ui
    config = ActiveScaffold::Config::Core.new(:company)
    @record = Company.new
    opts = {object: @record}
    assert active_scaffold_input_date_picker(config.columns[:date], opts.merge(id: 'record_date', name: 'record[date]'))
    assert active_scaffold_input_date_picker(config.columns[:datetime], opts.merge(id: 'record_date', name: 'record[datetime]'))
  end
end
