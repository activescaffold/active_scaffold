module ActionDispatch
  module Routing
    ACTIVE_SCAFFOLD_CORE_ROUTING = {
      :collection => {:show_search => :get, :render_field => :post, :mark => :post},
      :member => {:update_column => :post, :render_field => [:get, :post], :mark => :post}
    }
    ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING = {
      :collection => {:edit_associated => :get, :new_existing => :get, :add_existing => :post},
      :member => {:edit_associated => :get, :destroy_existing => :delete}
    }

    class Mapper
      module Resources
        class ActiveScaffold < Resource
          def default_actions
            @default_actions ||= (ACTIVE_SCAFFOLD_CORE_ROUTING[:collection].keys + ACTIVE_SCAFFOLD_CORE_ROUTING[:member].keys).uniq
          end
        end
        class ActiveScaffoldAssociation < Resource
          def default_actions
            @default_actions ||= (ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING[:collection].keys + ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING[:member].keys).uniq
          end
        end

        def as_routes(opts = {:association => true})
          resource = parent_resource
          resource_scope(:resource, ActiveScaffold.new(parent_resource.name, parent_resource.options)) do
            collection do
              ActionDispatch::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING[:collection].each do |name, type|
                match(name, :via => type) if parent_resource.actions.include? name
              end
            end
            member do
              ActionDispatch::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING[:member].each do |name, type|
                match(name, :via => type) if parent_resource.actions.include? name
              end
              get 'list', :action => :index if resource.actions.include? :index
            end
          end
          as_association_routes if opts[:association]
        end

        def as_association_routes
          resource_scope(:resource, ActiveScaffoldAssociation.new(parent_resource.name, parent_resource.options)) do
            collection do
              ActionDispatch::Routing::ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING[:collection].each do |name, type|
                match(name, :via => type) if parent_resource.actions.include? name
              end
            end
            member do
              ActionDispatch::Routing::ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING[:member].each do |name, type|
                match(name, :via => type) if parent_resource.actions.include? name
              end
            end
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
