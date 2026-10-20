# frozen_string_literal: true

class ActiveScaffold::Bridges::Choices < ActiveScaffold::DataStructures::Bridge
  autoload :Helpers, 'active_scaffold/bridges/choices/helpers'

  def self.install
    require File.join(File.dirname(__FILE__), 'choices/helpers')
  end

  def self.install?
    true
  end

  def self.javascripts
    'active_scaffold/choices'
  end
end
