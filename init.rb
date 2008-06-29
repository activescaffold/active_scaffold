##
## Initialize the environment
##
raise "This version of ActiveScaffold is compatible with Rails 2.0 or Rails 1.2.x.  Please use a later version." unless (Rails::VERSION::MAJOR == 2 && Rails::VERSION::MINOR == 0) || (Rails::VERSION::MAJOR == 1 && Rails::VERSION::MINOR >= 2)

require File.dirname(__FILE__) + '/environment'

##
## Run the install assets script, too, just to make sure
## But at least rescue the action in production
##
begin
  require File.dirname(__FILE__) + '/install_assets'
rescue
  raise $! unless RAILS_ENV == 'production'
end
