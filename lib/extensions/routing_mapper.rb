module ActionDispatch
  module Routing
    class Mapper
      module Base
        def as_routes(options = {:full => true})
          collection do 
            get :show_search, :render_field
          end
          member do
            get :row, :nested, :render_field, :delete
            post :update_column
          end
          as_extended_routes if options[:full]
        end
        
        def as_extended_routes
          collection do 
            get :edit_associated, :new_existing
            post :add_existing
          end
          member do
            get :edit_associated, :add_association
            delete :destroy_existing
          end
        end
      end
    end
  end
end
