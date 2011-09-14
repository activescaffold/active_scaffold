class ActiveScaffold::Bridges::TinyMCE < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), "tiny_mce/tiny_mce_bridge.rb")
  end
end
