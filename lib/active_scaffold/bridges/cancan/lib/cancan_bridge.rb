module ActiveScaffold
  module CancanBridge

    module Core
      extend ActiveSupport::Concern
      included do
        alias_method_chain :beginning_of_chain, :cancan
      end
      # :TODO can this be expanded more ?
      def beginning_of_chain_with_cancan
        beginning_of_chain_without_cancan.accessible_by(current_ability)
      end
    end

    # This is a module aimed at making the current_ability available to ActiveRecord models for permissions.
    module ModelUserAccess
      module Controller
        extend ActiveSupport::Concern
        included do
          prepend_before_filter :assign_current_ability_to_models
        end

        # We need to give the ActiveRecord classes a handle to the current ability. We don't want to just pass the object,
        # because the object may change (someone may log in or out). So we give ActiveRecord a proc that ties to the
        # current_ability_method on this ApplicationController.
        def assign_current_ability_to_models
          ::ActiveRecord::Base.current_ability_proc = proc {send(:current_ability)}
        end
      end

      module Model
        extend ActiveSupport::Concern

        module ClassMethods
          # The proc to call that retrieves the current_ability from the ApplicationController.
          attr_accessor :current_ability_proc

          # Class-level access to the current ability
          def current_ability
            ::ActiveRecord::Base.current_ability_proc.call if ::ActiveRecord::Base.current_ability_proc
          end
        end

        # Instance-level access to the current ability
        def current_ability; self.class.current_ability end
      end
    end


    module ActiveRecord
      extend ActiveSupport::Concern
      included do
        extend SecurityMethods
        include SecurityMethods
        alias_method_chain :authorized_for?, :cancan
        class << self
          alias_method_chain :authorized_for?, :cancan
        end
      end

      module SecurityMethods
        class InvalidArgument < StandardError; end

        # is usually called with :crud_type and :column, or :action
        #     {:crud_type=>:update, :column=>"some_colum_name"}
        #     {:action=>"edit"}
        # to allow access cancan must allow both :crud_type and :action
        # if cancan says "no", it delegates to default AS behavior
        def authorized_for_with_cancan?(options = {})
          raise InvalidArgument if options[:crud_type].blank? and options[:action].blank?
          if current_ability.present?
            crud_type_result = options[:crud_type].nil? ? true : current_ability.can?(options[:crud_type], self)
            action_result = options[:action].nil? ? true : current_ability.can?(options[:action].to_sym, self)
          else
            crud_type_result, action_result = false, false
          end
          default_result = authorized_for_without_cancan?(options)
          result = (crud_type_result && action_result) || default_result
          return result
        end
      end
    end

  end
end
