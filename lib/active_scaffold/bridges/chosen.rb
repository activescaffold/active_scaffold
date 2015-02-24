class ActiveScaffold::Bridges::Chosen < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'chosen/helpers.rb')
  end
  def self.install?
    super && [:jquery, :prototype].include?(ActiveScaffold.js_framework)
  end
  def self.stylesheets
    'chosen'
  end
  def self.javascripts
    ["chosen-#{ActiveScaffold.js_framework}", "#{ActiveScaffold.js_framework}/active_scaffold_chosen"]
  end
end
