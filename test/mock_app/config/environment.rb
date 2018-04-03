# Load the rails application
require File.expand_path('application', __dir__)

# Initialize the rails application
RailsApp::Application.config.root = File.expand_path('..', __dir__)
RailsApp::Application.initialize!
