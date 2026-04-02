# frozen_string_literal: true

module ActiveScaffold::Bridges
  class DatePicker < ActiveScaffold::DataStructures::Bridge
    autoload :Helper, 'active_scaffold/bridges/date_picker/helper'
    def self.install
      require File.join(File.dirname(__FILE__), 'date_picker/ext.rb')
    end

    def self.install?
      ActiveScaffold.jquery_ui_included?
    end

    mattr_accessor :default_ui
    @@default_ui = true

    def self.stylesheets
      'jquery-ui-timepicker-addon'
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
