class ActiveScaffold::Bridges::RecordSelect < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), "record_select/record_select_bridge.rb")
  end
end
