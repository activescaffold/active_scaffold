class ActiveScaffold::Bridges::Paperclip < ActiveScaffold::DataStructures::Bridge
  def self.install
    if ActiveScaffold::Config::Core.method_defined?(:initialize_with_paperclip)
      raise "We've detected that you have active_scaffold_paperclip_bridge installed. This plugin has been moved to core. Please remove active_scaffold_paperclip_bridge to prevent any conflicts"
    end
    require File.join(File.dirname(__FILE__), 'paperclip/form_ui')
    require File.join(File.dirname(__FILE__), 'paperclip/list_ui')
    require File.join(File.dirname(__FILE__), 'paperclip/paperclip_bridge_helpers')
    require File.join(File.dirname(__FILE__), 'paperclip/paperclip_bridge')
    ActiveScaffold::Config::Core.send :include, ActiveScaffold::Bridges::Paperclip::PaperclipBridge
  end
end
