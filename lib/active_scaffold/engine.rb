module ActiveScaffold
  class Engine < ::Rails::Engine
    initializer "active_scaffold.action_controller" do |app|
      ActiveSupport.on_load :action_controller do
        include ActiveScaffold::Core
        include ActiveScaffold::RespondsToParent
        include ActiveScaffold::Helpers::ControllerHelpers
        include ActiveRecordPermissions::ModelUserAccess::Controller
      end
    end

    initializer "active_scaffold.action_view" do |app|
      ActiveSupport.on_load :action_view do
        include ActiveScaffold::Helpers::ViewHelpers
      end
    end

    initializer "active_scaffold.active_record" do |app|
      ActiveSupport.on_load :active_record do
        include ActiveRecordPermissions::ModelUserAccess::Model
      end
    end

  end
end
