ActiveScaffold.bridge "FileColumn" do
  install do
    require File.join(File.dirname(__FILE__), "lib/as_file_column_bridge")
    require File.join(File.dirname(__FILE__), "lib/delete_file_column")
  end
end
