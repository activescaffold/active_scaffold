module ActiveScaffold
  class Engine < ::Rails::Engine
    initializer "active_scaffold.action_controller" do |app|
      ActiveSupport.on_load :action_controller do
        include ActiveScaffold::Core
        include ActiveScaffold::DelayedSetup if ActiveScaffold.delayed_setup
        include ActiveScaffold::RespondsToParent
        include ActiveScaffold::Helpers::ControllerHelpers
        include ActiveScaffold::ActiveRecordPermissions::ModelUserAccess::Controller
      end
    end

    initializer "active_scaffold.action_view" do |app|
      ActiveSupport.on_load :action_view do
        include ActiveScaffold::Helpers::ViewHelpers
      end
    end

    initializer "active_scaffold.active_record" do |app|
      ActiveSupport.on_load :active_record do
        include ActiveScaffold::ActiveRecordPermissions::ModelUserAccess::Model
        ActiveRecord::Associations::Association.send :include, ActiveScaffold::Tableless::Association
      end
    end

  end
end
