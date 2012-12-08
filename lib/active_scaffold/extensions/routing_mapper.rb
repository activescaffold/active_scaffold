module ActionDispatch
  module Routing
    ACTIVE_SCAFFOLD_CORE_ROUTING = {
        :collection => {:show_search => :get, :render_field => :post, :mark => :post},
        :member => {:row => :get, :update_column => :post, :render_field => [:get, :post], :mark => :post}
    }
    ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING = {
        :collection => {:edit_associated => :get, :new_existing => :get, :add_existing => :post},
        :member => {:edit_associated => :get, :destroy_existing => :delete}
    }
    class Mapper
      module Base
        def as_routes(options = {:association => true})
          collection do
            ActionDispatch::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING[:collection].each {|name, type| match(name, :via => type)}
          end
          member do
            ActionDispatch::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING[:member].each {|name, type| match(name, :via => type)}
            get 'list', :action => :index
          end
          as_association_routes if options[:association]
        end
        
        def as_association_routes
          collection do 
            ActionDispatch::Routing::ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING[:collection].each {|name, type| send(type, name)}
          end
          member do
            ActionDispatch::Routing::ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING[:member].each {|name, type| send(type, name)}
          end
        end
        
        def as_nested_resources(*resources)
          options = resources.extract_options!
          resources.each do |resource|
            resources(resource, options.merge(:parent_scaffold => merge_module_scope(@scope[:module], parent_resource.plural), :association => resource)) { yield if block_given? }
          end
        end
        
        def as_scoped_routes(*scopes)
          options = scopes.extract_options!
          scopes.each do |scope|
            resources(scope, options.merge(:parent_scaffold => merge_module_scope(@scope[:module], parent_resource.plural), :named_scope => scope, :controller => parent_resource.plural)) { yield if block_given? }
          end
        end
      end
    end
  end
end
