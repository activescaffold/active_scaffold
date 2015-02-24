require 'test_helper'
require File.join(File.dirname(__FILE__), '../../lib/active_scaffold/bridges/date_picker/ext')
# require File.join(File.dirname(__FILE__), '../../lib/active_scaffold/bridges/date_picker/helper')

class DatePickerTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ViewHelpers
  include ActiveScaffold::Bridges::DatePicker::Helper::FormColumnHelpers
  include ActiveScaffold::Bridges::DatePicker::Helper::DatepickerColumnHelpers

  def setup
    @controller.class.class_eval do
      include ActiveScaffold::Finder
    end
  end

  def test_set_form_ui
    config = ActiveScaffold::Config::Core.new(:company)
    assert_equal nil, config.columns[:name].form_ui, 'form_ui for name'
    assert_equal :date_picker, config.columns[:date].form_ui, 'form_ui for date'
    assert_equal :datetime_picker, config.columns[:datetime].form_ui, 'form_ui for datetime'
  end

  def test_form_ui
    config = ActiveScaffold::Config::Core.new(:company)
    @record = Company.new
    assert active_scaffold_input_date_picker(config.columns[:date], :name => 'record[date]', :id => 'record_date', :object => @record)
    assert active_scaffold_input_date_picker(config.columns[:datetime], :name => 'record[datetime]', :id => 'record_datetime', :object => @record)
  end
end
