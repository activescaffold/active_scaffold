ActiveScaffold.bridge "FileColumn" do
  install do
    if ActiveScaffold::Config::Core.instance_methods.include?("initialize_with_file_column")
      raise RuntimeError, "We've detected that you have active_scaffold_file_column_bridge installed.  This plugin has been moved to core.  Please remove active_scaffold_file_column_bridge to prevent any conflicts"
    end
    
    require File.join(File.dirname(__FILE__), "lib/as_file_column_bridge")
    require File.join(File.dirname(__FILE__), "lib/delete_file_column")
  end
end
