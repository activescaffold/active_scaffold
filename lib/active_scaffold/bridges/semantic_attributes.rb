class ActiveScaffold::Bridges::SemanticAttributes < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'semantic_attributes/column.rb')
  end
end
