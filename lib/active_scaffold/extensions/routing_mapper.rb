module ActiveScaffold
  module Routing
    ACTIVE_SCAFFOLD_CORE_ROUTING = {
      :collection => {:show_search => :get, :render_field => :post, :mark => :post},
      :member => {:update_column => :post, :render_field => %i[get post], :mark => :post}
    }.freeze
    ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING = {
      :collection => {:edit_associated => :get, :new_existing => :get, :add_existing => :post},
      :member => {:edit_associated => :get, :destroy_existing => :delete}
    }.freeze

    class Association
      def default_actions(actions_hash)
        (actions_hash[:collection].keys + actions_hash[:member].keys).uniq
      end

      def get_actions(actions_hash, options)
        default_actions = default_actions(actions_hash)
        if only = options[:only]
          Array(only).map(&:to_sym)
        elsif except = options[:except]
          default_actions - Array(except).map(&:to_sym)
        else
          default_actions
        end
      end

      def call(mapper, options = {})
        actions = get_actions(ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING, options)

        mapper.collection do
          ActionDispatch::Routing::ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING[:collection].each do |name, type|
            mapper.match(name, via: type) if actions.include? name
          end
        end

        mapper.member do
          ActionDispatch::Routing::ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING[:member].each do |name, type|
            mapper.match(name, via: type) if actions.include? name
          end
        end
      end
    end

    class Basic < Association
      def initialize(defaults = {})
        @defaults = defaults
      end

      def call(mapper, options = {})
        options = @defaults.merge(options)
        actions = get_actions(ACTIVE_SCAFFOLD_CORE_ROUTING, options)

        mapper.collection do
          ActionDispatch::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING[:collection].each do |name, type|
            mapper.match(name, via: type) if actions.include? name
          end
        end

        mapper.member do
          ActionDispatch::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING[:member].each do |name, type|
            mapper.match(name, via: type) if actions.include? name
          end
          mapper.get 'list', action: :index if mapper.send(:parent_resource).actions.include? :index
        end

        super if options[:association]
      end
    end
  end
end

module ActionDispatch
  module Routing
    ACTIVE_SCAFFOLD_CORE_ROUTING = ActiveScaffold::Routing::ACTIVE_SCAFFOLD_CORE_ROUTING
    ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING = ActiveScaffold::Routing::ACTIVE_SCAFFOLD_ASSOCIATION_ROUTING

    class Mapper
      module Resources
        def parent_options
          opts = parent_resource.instance_variable_get(:@options)
          if Rails.version >= '5.0.0'
            opts.merge(
              only: parent_resource.instance_variable_get(:@only),
              except: parent_resource.instance_variable_get(:@except)
            )
          end
          opts
        end

        def define_active_scaffold_concern
          ActiveSupport::Deprecation.warn 'Add concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true) to your routes file.'
          concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)
        end

        def define_active_scaffold_association_concern
          ActiveSupport::Deprecation.warn 'Add concern :active_scaffold_association, ActiveScaffold::Routing::Association.new to your routes file.'
          concern :active_scaffold_association, ActiveScaffold::Routing::Association.new
        end

        def as_routes(opts = {association: true})
          define_active_scaffold_concern unless @concerns[:active_scaffold]
          if opts[:association] && !@concerns[:active_scaffold_association]
            define_active_scaffold_association_concern
          end
          ActiveSupport::Deprecation.warn 'Use concerns: :active_scaffold in resources instead of as_routes, or concerns :active_scaffold in resources block if want to disable association routes or restrict routes with only or except options.'
          concerns :active_scaffold, parent_options.merge(association: opts[:association])
        end

        def as_association_routes
          define_active_scaffold_association_concern unless @concerns[:active_scaffold_association]
          ActiveSupport::Deprecation.warn 'Use concerns: :active_scaffold_association in resources instead of as_association_routes, or concerns :active_scaffold_association in resources block if want to restrict routes with only or except options.'
          concerns :active_scaffold_association, parent_options
        end

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
