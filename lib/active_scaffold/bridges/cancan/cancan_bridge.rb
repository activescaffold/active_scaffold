# frozen_string_literal: true

# Allow users to easily define aliases for AS actions.
# Ability#as_action_aliases should be called by the user in his ability class
#
#     class Ability < CanCan::Ability
#       def initialize(user)
#         as_action_aliases
#       end
#     end
#
module CanCan
  module Ability
    def as_action_aliases
      alias_action :list, :show_search, :render_field, to: :read
      alias_action :update_column, :edit_associated, :new_existing, :add_existing, to: :update
      alias_action :delete, :destroy_existing, to: :destroy
    end
  end
end

module ActiveScaffold::Bridges
  class Cancan
    # controller level authorization
    # As already has callbacks to ensure authorization at controller method via "authorization_method"
    # but let's include this too, just in case, no sure how performance is affected tough :TODO benchmark
    module ClassMethods
      def active_scaffold(model_id = nil, &)
        super
        authorize_resource(
          class: active_scaffold_config.model,
          instance: :record
        )
      end
    end

    module AssociationHelpers
      def association_klass_scoped(association, klass, record)
        super.accessible_by(current_ability, :read)
      end
    end

    # beginning of chain integration
    module Actions
      module Core
        # :TODO can this be expanded more ?
        def beginning_of_chain
          super.accessible_by(current_ability)
        end

        # fix when ability allow access base on id
        # can [:manage], Client, id: Client.of_employee(user).pluck(:id)
        def new_model
          super.tap { |record| record.id = nil }
        end
      end
    end

    # This is a module aimed at making the current_ability available to ActiveRecord models for permissions.
    module ModelUserAccess
      module Controller
        extend ActiveSupport::Concern

        included do
          prepend_before_action :assign_current_ability_to_models
        end

        # We need to give the ActiveRecord classes a handle to the current ability. We don't want to just pass the object,
        # because the object may change (someone may log in or out). So we give ActiveRecord a proc that ties to the
        # current_ability_method on this ApplicationController.
        def assign_current_ability_to_models
          ::ActiveScaffold::Registry.current_ability_proc = proc { send(:current_ability) }
        end
      end

      module Model
        extend ActiveSupport::Concern

        module ClassMethods
          # Class-level access to the current ability
          def current_ability
            ::ActiveScaffold::Registry.current_ability_proc&.call
          end
        end

        # Instance-level access to the current ability
        delegate :current_ability, to: :class
      end
    end

    # plug into AS#authorized_for calls
    module ActiveRecord
      extend ActiveSupport::Concern

      included do
        prepend SecurityMethods

        class << self
          prepend SecurityMethods
        end
      end

      module SecurityMethods
        class InvalidArgument < StandardError; end

        # is usually called with :crud_type and :column, or :action
        #     {crud_type: :update, column: 'some_colum_name'}
        #     {action: 'edit'}
        # to allow access cancan must allow both :crud_type and :action
        # if cancan says "no", it delegates to default AS behavior
        def authorized_for?(options = {}) # rubocop:disable Naming/PredicateMethod
          raise InvalidArgument if options[:crud_type].blank? && options[:action].blank?

          if current_ability.present?
            crud_type_result = options[:crud_type].nil? || current_ability.can?(options[:crud_type], self)
            action_result = options[:action].nil? || current_ability.can?(options[:action].to_sym, self)
          else
            crud_type_result = action_result = false
          end
          result = (crud_type_result && action_result) || super(options.merge(reason: nil))
          # return array with nil reason if requested with options[:reason], we don't have reason but caller expects array
          options[:reason] ? [result, nil] : result
        end
      end
    end
  end
end
