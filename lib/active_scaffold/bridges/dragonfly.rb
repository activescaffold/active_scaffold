class ActiveScaffold::Bridges::Dragonfly < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'dragonfly/form_ui')
    require File.join(File.dirname(__FILE__), 'dragonfly/list_ui')
    require File.join(File.dirname(__FILE__), 'dragonfly/dragonfly_bridge_helpers')
    require File.join(File.dirname(__FILE__), 'dragonfly/dragonfly_bridge')
    ActiveScaffold::Config::Core.send :include, ActiveScaffold::Bridges::Dragonfly::DragonflyBridge
  end
end
