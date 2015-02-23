module ActiveScaffold::Bridges
  class DatePicker < ActiveScaffold::DataStructures::Bridge
    autoload :Helper, 'active_scaffold/bridges/date_picker/helper'
    def self.install
      require File.join(File.dirname(__FILE__), 'date_picker/ext.rb')
    end
    def self.install?
      ActiveScaffold.js_framework == :jquery && jquery_ui_included?
    end
    def self.jquery_ui_included?
      Jquery::Rails.const_defined?('JQUERY_UI_VERSION') || Jquery.const_defined?('Ui') if Object.const_defined?('Jquery')
    end
    def self.localization
      "jQuery(function($){
  if (typeof($.datepicker) === 'object') {
    #{Helper.date_options_for_locales}
    $.datepicker.setDefaults($.datepicker.regional['#{::I18n.locale}']);
  }
  if (typeof($.timepicker) === 'object') {
    #{Helper.datetime_options_for_locales}
    $.timepicker.setDefaults($.timepicker.regional['#{::I18n.locale}']);
  }
});\n"
    end
  end
end
