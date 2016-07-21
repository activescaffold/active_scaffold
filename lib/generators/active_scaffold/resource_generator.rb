require 'rails/generators/rails/resource/resource_generator'
# require 'generators/active_scaffold_controller/active_scaffold_controller_generator'

module ActiveScaffold
  module Generators
    class ResourceGenerator < Rails::Generators::ResourceGenerator # metagenerator
      remove_hook_for :resource_controller
      remove_hook_for :resource_route
      remove_class_option :actions

      desc <<-DESC.strip_heredoc
      Description:
          Scaffolds an entire resource, from model and migration to controller,
              along with a full test suite and configured to use active_scaffold.
          The resource is ready to use as a starting point for your RESTful,
              resource-oriented application.

          Pass the name of the model (in singular form), either CamelCased or
              under_scored, as the first argument, and an optional list of attribute
          pairs.

          Attribute pairs are field:type arguments specifying the
          model's attributes. Timestamps are added by default, so you don't have to
          specify them by hand as 'created_at:datetime updated_at:datetime'.

          You don't have to think up every attribute up front, but it helps to
          sketch out a few so you can start working with the resource immediately.

          For example, 'active_scaffold post title:string body:text published:boolean'
          gives you a model with those three attributes, a controller configured to use active_scaffold,
          as well as a resources :posts with additional active_scaffold routes
          declaration in config/routes.rb.

          If you want to remove all the generated files, run
          'rails destroy active_scaffold ModelName'.

      Examples:
          `rails generate active_scaffold:resource post`
          `rails generate active_scaffold:resource post title:string body:text published:boolean`
          `rails generate active_scaffold:resource purchase order_id:integer amount:decimal`
      DESC

      def add_resource_route
        routing_code =  class_path.collect { |namespace| "namespace :#{namespace} do " }.join(' ')
        routing_code << "resources :#{file_name.pluralize}, concerns: :active_scaffold"
        routing_code << ' end' * class_path.size
        log :route, routing_code
        in_root do
          inject_into_file 'config/routes.rb', "  #{routing_code}\n", { after: /^[ ]*concern :active_scaffold,.*\n/, verbose: false, force: true }
        end
      end

      invoke 'active_scaffold:controller'
    end
  end
end
