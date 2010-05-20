ActiveScaffold.bridge "DependentProtect" do
  install do
    # check to see if the old bridge was installed.  If so, warn them
    # we can detect this by checking to see if the bridge was installed before calling this code
    if ActiveRecord::Base.instance_methods.include?("authorized_for_delete?")
      raise RuntimeError, "We've detected that you have active_scaffold_dependent_protect installed.  This plugin has been moved to core.  Please remove active_scaffold_dependent_protect to prevent any conflicts"
    end
    require File.join(File.dirname(__FILE__), "lib/dependent_protect_bridge.rb")
  end
end
