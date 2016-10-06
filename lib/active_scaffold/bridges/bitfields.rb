class ActiveScaffold::Bridges::Bitfields < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'bitfields/bitfields_bridge')
    ActiveScaffold::Config::Core.send :prepend, ActiveScaffold::Bridges::Bitfields::BitfieldsBridge
  end
end
