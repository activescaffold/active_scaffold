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

    # Data-only equivalent of .localization, consumed directly by load.js without eval,
    # so it works under a CSP that disallows 'unsafe-eval'.
    def self.localization_data
      {
        locale: ::I18n.locale.to_s,
        datepickerRegional: Helper.date_options_by_locale,
        timepickerRegional: Helper.datetime_options_by_locale
      }
    end
  end
end
