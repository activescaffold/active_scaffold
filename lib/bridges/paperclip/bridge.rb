require File.join(File.dirname(__FILE__), "lib/paperclip_bridge_helpers")
ActiveScaffold.bridge "Paperclip" do
  install do
    if ActiveScaffold::Config::Core.instance_methods.include?("initialize_with_paperclip")
      raise RuntimeError, "We've detected that you have active_scaffold_paperclip_bridge installed. This plugin has been moved to core. Please remove active_scaffold_paperclip_bridge to prevent any conflicts"
    end

    require File.join(File.dirname(__FILE__), "lib/paperclip_bridge")
    require File.join(File.dirname(__FILE__), "lib/form_ui")
    require File.join(File.dirname(__FILE__), "lib/list_ui")
  end
end