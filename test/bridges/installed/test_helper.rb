# frozen_string_literal: true

# Load optional gems before the application boots so ActiveScaffold's engine
# sees their constants when it runs the bridges.
require 'rails'
require 'action_view'
require 'active_record'
require 'ancestry'
require 'bitfields'
require 'cancan'
require 'carrierwave'
require 'chosen-rails'
require 'country_select'
require 'dragonfly'
require 'jquery-ui-rails'
require 'logical_query_parser'
require 'paperclip'
require 'paper_trail'
require 'record_select'
require 'tinymce-rails'

require_relative '../../test_helper'

# ActiveScaffold installs bridges lazily on the first `active_scaffold` call.
# Run the same installation step explicitly so this suite can inspect every
# optional bridge without defining a controller for each gem.
ActiveScaffold::Bridges.run_all

module InstalledBridgeAssertions
  BRIDGE_GEMS = {
    ancestry: %w[ancestry Ancestry],
    bitfields: %w[bitfields Bitfields],
    cancan: %w[cancancan CanCan],
    carrierwave: %w[carrierwave CarrierWave],
    chosen: %w[chosen-rails Chosen],
    country_select: %w[country_select CountrySelect],
    date_picker: %w[jquery-ui-rails Jquery::Ui],
    dragonfly: %w[dragonfly Dragonfly],
    logical_query_parser: %w[logical_query_parser LogicalQueryParser],
    paperclip: %w[kt-paperclip Paperclip],
    paper_trail: %w[paper_trail PaperTrail],
    record_select: %w[recordselect RecordSelect],
    tiny_mce: %w[tinymce-rails TinyMCE]
  }.freeze

  def assert_installed_bridge(bridge_name)
    gem_name, constant_name = BRIDGE_GEMS.fetch(bridge_name)
    assert_predicate Gem::Specification.find_all_by_name(gem_name), :any?, "#{gem_name} is not installed"
    assert Object.const_defined?(constant_name), "#{constant_name} was not loaded from #{gem_name}"

    bridge = ActiveScaffold::Bridges[bridge_name]
    assert bridge, "No bridge registered for #{bridge_name}"
    assert_predicate bridge, :install?, "#{bridge_name} did not detect #{gem_name}"
    bridge
  end
end
