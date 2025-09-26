# frozen_string_literal: true

class ActiveScaffold::Bridges::Chosen < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'chosen/helpers.rb')
  end

  def self.stylesheets
    'chosen'
  end

  def self.javascripts
    ['chosen-jquery', 'jquery/active_scaffold_chosen']
  end
end
