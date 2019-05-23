class ActiveScaffold::Bridges::Bitfields < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'bitfields/bitfields_bridge')
    ActiveScaffold::Config::Core.send :prepend, ActiveScaffold::Bridges::Bitfields::BitfieldsBridge
    ActiveScaffold::Config::Core.after_config_callbacks << :_setup_bitfields
  end
end
