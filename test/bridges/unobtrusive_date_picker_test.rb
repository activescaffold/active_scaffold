require 'test/unit'
require File.join(File.dirname(__FILE__), 'company')
require File.join(File.dirname(__FILE__), '../../lib/bridges/unobtrusive_date_picker/lib/unobtrusive_date_picker_bridge')
require File.join(File.dirname(__FILE__), '../../lib/bridges/unobtrusive_date_picker/lib/view_helpers')
require File.join(File.dirname(__FILE__), '../../lib/bridges/unobtrusive_date_picker/lib/form_ui')

class UDPCore < ActiveScaffold::Config::Core
  include ActiveScaffold::UnobtrusiveDatePickerBridge
end

class UnobtrusiveDatePickerTest < ActionView::TestCase
  include ActiveScaffold::Helpers::ViewHelpers
  include ActiveScaffold::UnobtrusiveDatePickerHelpers

  def test_set_form_ui
    config = UDPCore.new(:company)
    assert_equal nil, config.columns[:name].form_ui, 'form_ui for name'
    assert_equal :datepicker, config.columns[:date].form_ui, 'form_ui for date'
    assert_equal :datepicker, config.columns[:datetime].form_ui, 'form_ui for datetime'
  end

  def test_stylesheets
    assert active_scaffold_stylesheets.include?('datepicker.css')
  end

  def test_javascripts
    assert active_scaffold_javascripts.include?('datepicker.js')
    assert active_scaffold_javascripts.include?('datepicker_lang/es.js')
  end

  def test_form_ui
    config = UDPCore.new(:company)
    self.expects(:date_select).returns('')
    self.expects(:date_picker).returns('')
    assert active_scaffold_input_datepicker(config.columns[:date], :name => 'record[date]', :id => 'record_date')

    self.expects(:datetime_select).returns('')
    self.expects(:date_picker).returns('')
    assert active_scaffold_input_datepicker(config.columns[:datetime], :name => 'record[datetime]', :id => 'record_datetime')
  end

  private
  def unobtrusive_datepicker_stylesheets
    ['datepicker.css']
  end
  def unobtrusive_datepicker_javascripts
    ['datepicker.js', 'datepicker_lang/es.js']
  end
end
