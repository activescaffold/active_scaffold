require 'active_scaffold'

begin
  ActiveScaffoldAssets.copy_to_public(ActiveScaffold.root, {:clean_up_destination => true})
rescue
  raise $! unless Rails.env == 'production'
end