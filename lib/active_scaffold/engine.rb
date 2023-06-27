module ActiveScaffold
  class Engine < ::Rails::Engine
    initializer 'active_scaffold.action_controller' do
      ActiveSupport.on_load :action_controller do
        include ActiveScaffold::Core
        include ActiveScaffold::RespondsToParent
        include ActiveScaffold::Helpers::ControllerHelpers
        include ActiveScaffold::ActiveRecordPermissions::ModelUserAccess::Controller
        ActiveScaffold::Bridges.prepare_all
      end
    end

    initializer 'active_scaffold.action_view' do
      ActiveSupport.on_load :action_view do
        include ActiveScaffold::Helpers::ViewHelpers
      end
    end

    initializer 'active_scaffold.active_record' do
      ActiveSupport.on_load :active_record do
        include ActiveScaffold::ActiveRecordPermissions::ModelUserAccess::Model
        module ActiveRecord::Associations
          Association.send :include, ActiveScaffold::Tableless::Association
          CollectionAssociation.send :include, ActiveScaffold::Tableless::CollectionAssociation
          SingularAssociation.send :include, ActiveScaffold::Tableless::SingularAssociation
        end
        module ActiveRecord::ConnectionAdapters
          AbstractAdapter.send :include, ActiveScaffold::ConnectionAdapters::AbstractAdapter
          if defined?(PostgreSQLAdapter)
            PostgreSQLAdapter.send :include, ActiveScaffold::ConnectionAdapters::PostgreSQLAdapter
          end
          if defined?(SQLServerAdapter)
            SQLServerAdapter.send :include, ActiveScaffold::ConnectionAdapters::SQLServerAdapter
          end
        end
      end
    end

    initializer 'active_scaffold.assets' do
      config.assets.precompile << 'active_scaffold/indicator.gif'
    end
  end
end
