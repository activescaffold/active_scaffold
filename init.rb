##
## Initialize the environment
##
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
