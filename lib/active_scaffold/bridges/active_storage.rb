class ActiveScaffold::Bridges::ActiveStorage < ActiveScaffold::DataStructures::Bridge
  def self.install
    if ActiveScaffold::Config::Core.method_defined?(:initialize_with_active_storage)
      raise "We've detected that you have active_scaffold_active_storage_bridge installed. This plugin has been moved to core. Please remove active_scaffold_active_storage_bridge to prevent any conflicts"
    end
    require File.join(File.dirname(__FILE__), 'active_storage/active_storage_bridge')
    require File.join(File.dirname(__FILE__), 'active_storage/form_ui')
    require File.join(File.dirname(__FILE__), 'active_storage/list_ui')
    require File.join(File.dirname(__FILE__), 'active_storage/active_storage_helpers')
    ActiveScaffold::Config::Core.send :prepend, ActiveScaffold::Bridges::ActiveStorage::ActiveStorageBridge
  end
end
