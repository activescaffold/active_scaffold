# frozen_string_literal: true

module ActiveScaffold
  module Routing
    ACTIVE_SCAFFOLD_CORE_ROUTING = {
      collection: {show_search: :get, render_field: :post, mark: :post},
      member: {update_column: :post, render_field: %i[get post], mark: :post}
    }.freeze
    ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING = {
      collection: {edit_associated: :get, new_existing: :get, add_existing: :post},
      member: {edit_associated: :get, destroy_existing: :delete}
    }.freeze

    class Association
      def default_actions(actions_hash)
        (actions_hash[:collection].keys + actions_hash[:member].keys).uniq
      end

      def get_actions(actions_hash, options)
        default_actions = default_actions(actions_hash)
        if (only = options[:only])
          Array(only).map(&:to_sym)
        elsif (except = options[:except])
          default_actions - Array(except).map(&:to_sym)
        else
          default_actions
        end
      end

      def call(mapper, options = {})
        actions = get_actions(ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING, options)

        mapper.collection do
          ActiveScaffold::Routing::ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING[:collection].each do |name, type|
            mapper.match(name, via: type) if actions.include? name
          end
        end

        mapper.member do
          ActiveScaffold::Routing::ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING[:member].each do |name, type|
            mapper.match(name, via: type) if actions.include? name
          end
        end
      end
    end

    class Basic < Association
      def initialize(defaults = {})
        super()
        @defaults = defaults
      end

      def call(mapper, options = {})
        options = @defaults.merge(options)
        actions = get_actions(ACTIVE_SCAFFOLD_CORE_ROUTING, options)

        mapper.collection do
          ActiveScaffold::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING[:collection].each do |name, type|
            mapper.match(name, via: type) if actions.include? name
          end
        end

        mapper.member do
          ActiveScaffold::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING[:member].each do |name, type|
            mapper.match(name, via: type) if actions.include? name
          end
          mapper.get 'list', action: :index if mapper.send(:parent_resource).actions.include? :index
        end

        super if options[:association]
      end
    end
  end
  ActiveSupport.run_load_hooks(:active_scaffold_routing, Routing)
end

module ActionDispatch
  module Routing
    class Mapper
      module Resources
        def as_nested_resources(*resources)
          options = resources.extract_options!
          nested_options = options.merge(parent_scaffold: parent_scaffold)
          resources.each do |resource|
            resources(resource, nested_options.merge(association: resource)) { yield if block_given? }
          end
        end

        def as_scoped_routes(*scopes)
          options = scopes.extract_options!
          scoped_options = options.merge(parent_scaffold: parent_scaffold, association: parent_resource.plural)
          scopes.each do |scope|
            resources(scope, scoped_options.merge(named_scope: scope)) { yield if block_given? }
          end
        end

        def parent_scaffold
          merge_module_scope(@scope[:module], parent_resource.plural)
        end
      end
    end
  end
end
