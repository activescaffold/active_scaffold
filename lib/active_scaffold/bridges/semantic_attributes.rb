class ActiveScaffold::Bridges::SemanticAttributes < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), "semantic_attributes/semantic_attributes_bridge.rb")
  end
end
