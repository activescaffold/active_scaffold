# frozen_string_literal: true

module ActiveScaffold
  class Engine < ::Rails::Engine
    initializer 'active_scaffold.action_controller' do
      ActiveSupport.on_load :action_controller do
        require 'active_scaffold/extensions/action_controller_rescueing'
        require 'active_scaffold/extensions/action_controller_rendering'
        include ActiveScaffold::Core
        include ActiveScaffold::RespondsToParent
        include ActiveScaffold::Helpers::ControllerHelpers
        include ActiveScaffold::ActiveRecordPermissions::ModelUserAccess::Controller
      end
    end

    config.after_initialize do
      require 'active_scaffold/extensions/routing_mapper'
      ActiveScaffold::Bridges.prepare_all
    end

    initializer 'active_scaffold.action_view' do
      ActiveSupport.on_load :action_view do
        require 'active_scaffold/extensions/action_view_rendering'
        require 'active_scaffold/extensions/name_option_for_datetime'
        include ActiveScaffold::Helpers::ViewHelpers
      end
    end

    initializer 'active_scaffold.active_record' do
      ActiveSupport.on_load :active_record do
        require 'active_scaffold/extensions/to_label'
        require 'active_scaffold/extensions/unsaved_associated'
        require 'active_scaffold/extensions/unsaved_record'
        include ActiveScaffold::ActiveRecordPermissions::ModelUserAccess::Model
        ActiveRecord::Associations.module_eval do
          self::Association.include ActiveScaffold::Tableless::Association
          self::CollectionAssociation.include ActiveScaffold::Tableless::CollectionAssociation
          self::SingularAssociation.include ActiveScaffold::Tableless::SingularAssociation
        end

        ActiveRecord::ConnectionAdapters.module_eval do
          self::AbstractAdapter.include ActiveScaffold::ConnectionAdapters::AbstractAdapter
          if const_defined?(:PostgreSQLAdapter)
            self::PostgreSQLAdapter.include ActiveScaffold::ConnectionAdapters::PostgreSQLAdapter
          end
          if const_defined?(:SQLServerAdapter)
            self::SQLServerAdapter.include ActiveScaffold::ConnectionAdapters::SQLServerAdapter
          end
        end
      end
    end

    initializer 'active_scaffold.extensions' do
      require 'active_scaffold/extensions/ice_nine'
      require 'active_scaffold/extensions/localize'
      require 'active_scaffold/extensions/paginator_extensions'
    end
  end
end
