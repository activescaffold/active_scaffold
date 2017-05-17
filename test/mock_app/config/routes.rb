Rails.application.routes.draw do
  concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)
  concern :active_scaffold_association, ActiveScaffold::Routing::Association.new

  resources :addresses, concerns: :active_scaffold
  resources :buildings, except: :index do
    concerns :active_scaffold, except: %i[mark add_existing new_existing destroy_existing]
  end
  resources :cars, only: %i[edit update] do
    concerns :active_scaffold, association: false, except: [:mark]
  end

  match ':controller(/:action(/:id))', :via => :any
end
