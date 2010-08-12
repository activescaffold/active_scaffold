module ActionDispatch
  module Routing
    ACTIVE_SCAFFOLD_CORE_ROUTING = {
        :collection => {:show_search => :get, :render_field => :get},
        :member => {:row => :get, :update_column => :post, :render_field => :get, :delete => :get}
    }
    ACTIVE_SCAFFOLD_HABTM_ROUTING = {
        :collection => {:edit_associated => :get, :new_existing => :get, :add_existing => :post},
        :member => {:edit_associated => :get, :add_association => :get, :destroy_existing => :delete}
    }
    class Mapper
      module Base
        def as_routes(options = {:habtm => true})
          collection do
            ActionDispatch::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING[:collection].each {|name, type| send(type, name)}
          end
          member do
            ActionDispatch::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING[:member].each {|name, type| send(type, name)}
          end
          as_habtm_routes if options[:habtm]
        end
        
        def as_habtm_routes
          collection do 
            ActionDispatch::Routing::ACTIVE_SCAFFOLD_HABTM_ROUTING[:collection].each {|name, type| send(type, name)}
          end
          member do
            ActionDispatch::Routing::ACTIVE_SCAFFOLD_HABTM_ROUTING[:member].each {|name, type| send(type, name)}
          end
        end
      end
    end
  end
end
