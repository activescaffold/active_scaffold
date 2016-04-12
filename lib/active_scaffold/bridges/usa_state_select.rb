class ActiveScaffold::Bridges::UsaStateSelect < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'usa_state_select/usa_state_select_helper.rb')
  end

  def self.install?
    true
  end
end
