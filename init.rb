##
## Initialize the environment
##
unless Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR >= 0
  raise "This version of ActiveScaffold requires Rails 3.0 or higher.  Please use an earlier version."
end

require File.dirname(__FILE__) + '/environment'

##
## Run the install assets script, too, just to make sure
## But at least rescue the action in production
##
begin
  ActiveScaffoldAssets.copy_to_public(File.dirname(__FILE__), {:clean_up_destination => true})
rescue
  raise $! unless Rails.env == 'production'
end
