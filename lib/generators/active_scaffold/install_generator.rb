require 'rails/generators/base'
# require 'generators/active_scaffold_controller/active_scaffold_controller_generator'

module ActiveScaffold
  module Generators
    class InstallGenerator < Rails::Generators::Base # metagenerator
      desc "Add concerns to routes and require lines to assets manifest files"

      def add_concern_routes
        route "concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)"
        route "concern :active_scaffold_association, ActiveScaffold::Routing::Association.new"
      end

      def add_to_javascript_manifest
        original_js = File.binread("app/assets/javascripts/application.js")
        if original_js.include?("require active_scaffold")
          say_status("skipped", "insert into app/assets/javascripts/application.js", :yellow)
        else
          insert_into_file "app/assets/javascripts/application.js", :after => %r{//= require +['"]?jquery['"]?\n} do
            "//= require active_scaffold\n"
          end
        end
      end

      def add_to_stylesheet_manifest
        original_css = File.binread("app/assets/stylesheets/application.css")
        if original_css =~ /require active_scaffold$/
          say_status("skipped", "insert into app/assets/stylesheets/application.css", :yellow)
        else
          insert_into_file "app/assets/stylesheets/application.css", :before => %r{[ ]*\*/} do
            " *= require active_scaffold\n"
          end
        end
      end
    end
  end
end
