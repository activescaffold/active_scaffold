require 'rails/generators/rails/resource/resource_generator'
# require 'generators/active_scaffold_controller/active_scaffold_controller_generator'

module ActiveScaffold
  module Generators
    class ResourceGenerator < Rails::Generators::ResourceGenerator
      def self.base_root
        File.expand_path '../..', __dir__
      end

      remove_hook_for :resource_controller
      remove_hook_for :resource_route
      remove_class_option :actions

      def add_resource_route
        routing_code =  class_path.collect { |namespace| "namespace :#{namespace} do " }.join(' ')
        routing_code << "resources :#{file_name.pluralize}, concerns: :active_scaffold"
        routing_code << (' end' * class_path.size)
        log :route, routing_code
        in_root do
          inject_into_file 'config/routes.rb', "  #{routing_code}\n", after: /^[ ]*concern :active_scaffold,.*\n/, verbose: false, force: true
        end
      end

      invoke 'active_scaffold:controller'
    end
  end
end
