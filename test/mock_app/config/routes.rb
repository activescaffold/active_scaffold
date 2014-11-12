RailsApp::Application.routes.draw do
  resources :addresses do
    as_routes
  end
  match ':controller(/:action(/:id))', :via => :any
end
