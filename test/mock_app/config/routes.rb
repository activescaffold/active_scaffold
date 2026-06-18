Rails.application.routes.draw do
  concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)
  concern :active_scaffold_association, ActiveScaffold::Routing::Association.new

  resources :addresses, concerns: :active_scaffold
  resources :buildings, except: :index do
    concerns :active_scaffold, except: %i[mark add_existing new_existing destroy_existing]
  end
  resources :cars, only: %i[index edit update] do
    concerns :active_scaffold, association: false, except: [:mark]
  end
  resources :people do
    concerns :active_scaffold, except: %i[mark]
  end

  # Tabs test models
  resources :categories, concerns: :active_scaffold
  resources :tasks, concerns: :active_scaffold
  resources :milestones, concerns: :active_scaffold
  # tabs by belongs_to association + shared tabs with different FK column names
  resources :projects do
    concerns :active_scaffold
  end
  # tabs by a DB column with :select form_ui (uses same Project model)
  resources :projects_by_priority, controller: :projects_by_priority do
    concerns :active_scaffold
  end

  match ':controller(/:action(/:id))', :via => :any
end
