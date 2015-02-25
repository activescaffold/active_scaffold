class ActiveScaffold::Bridges::FileColumn < ActiveScaffold::DataStructures::Bridge
  def self.install
    if ActiveScaffold::Config::Core.method_defined?(:initialize_with_file_column)
      raise "We've detected that you have active_scaffold_file_column_bridge installed.  This plugin has been moved to core.  Please remove active_scaffold_file_column_bridge to prevent any conflicts"
    end
    require File.join(File.dirname(__FILE__), 'file_column/as_file_column_bridge')
    require File.join(File.dirname(__FILE__), 'file_column/form_ui')
    require File.join(File.dirname(__FILE__), 'file_column/list_ui')
    require File.join(File.dirname(__FILE__), 'file_column/file_column_helpers')
  end
end
