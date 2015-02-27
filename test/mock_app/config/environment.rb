# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
RailsApp::Application.config.root = File.expand_path('../..', __FILE__)
RailsApp::Application.initialize!
