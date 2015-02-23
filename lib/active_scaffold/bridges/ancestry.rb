class ActiveScaffold::Bridges::Ancestry < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'ancestry/ancestry_bridge.rb')
  end
end
