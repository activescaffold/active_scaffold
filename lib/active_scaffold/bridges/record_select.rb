# frozen_string_literal: true

class ActiveScaffold::Bridges::RecordSelect < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'record_select/helpers.rb')
  end

  def self.stylesheets
    'record_select'
  end

  def self.javascripts
    assets = ['record_select']
    assets << 'active_scaffold/record_select_bridge' if callback_registry?
    assets
  end

  def self.callback_registry?
    defined?(::RecordSelect) && ::RecordSelect.respond_to?(:callback_registry?) && ::RecordSelect.callback_registry?
  end
end
