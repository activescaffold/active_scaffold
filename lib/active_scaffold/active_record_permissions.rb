# frozen_string_literal: true

# This module attempts to create permissions conventions for your ActiveRecord models. It supports english-based
# methods that let you restrict access per-model, per-record, per-column, per-action, and per-user. All at once.
#
# You may define instance methods in the following formats:
#  def #{column}_authorized_for_#{action}?
#  def #{column}_authorized?
#  def authorized_for_#{action}?
#
# Your methods should allow for the following special cases:
#   * cron scripts
#   * guest users (or nil current_user objects)
module ActiveScaffold
  module ActiveRecordPermissions
    # ActiveRecordPermissions needs to know what method on your ApplicationController will return the current user,
    # if available. This defaults to the :current_user method. You may configure this in your environment.rb if you
    # have a different setup.
    mattr_accessor :current_user_method, default: :current_user

    # Whether the default permission is permissive or not
    # If set to true, then everything's allowed until configured otherwise
    mattr_accessor :default_permission, default: true

    # if enabled, string returned on authorized methods will be interpreted as not authorized and used as reason
    mattr_accessor :not_authorized_reason, default: false

    # This is a module aimed at making the current_user available to ActiveRecord models for permissions.
    module ModelUserAccess
      module Controller
        def self.included(base)
          base.prepend_before_action :assign_current_user_to_models
        end

        # We need to give the ActiveRecord classes a handle to the current user. We don't want to just pass the object,
        # because the object may change (someone may log in or out). So we give ActiveRecord a proc that ties to the
        # current_user_method on this ApplicationController.
        def assign_current_user_to_models
          ActiveScaffold::Registry.current_user_proc = proc { send(ActiveRecordPermissions.current_user_method) }
        end
      end

      module Model
        def self.included(base)
          base.extend ClassMethods
          base.send :include, ActiveRecordPermissions::Permissions
        end

        module ClassMethods
          # Class-level access to the current user
          def current_user
            ActiveScaffold::Registry.current_user_proc&.call
          end
        end

        # Instance-level access to the current user
        delegate :current_user, to: :class
      end
    end

    module Permissions
      def self.included(base)
        base.extend SecurityMethods
        base.send :include, SecurityMethods
        class << base
          attr_accessor :class_security_methods, :instance_security_methods
        end
      end

      # Because any class-level queries get delegated to the instance level via a new record,
      # it's useful to know when the authorization query is meant for a specific record or not.
      # But using new_record? is confusing, even though accurate. So this is basically just a wrapper.
      def existing_record_check?
        !new_record?
      end

      module SecurityMethods
        # A generic authorization query. This is what will be called programatically, since
        # the actual permission methods can't be guaranteed to exist. And because we want to
        # intelligently combine multiple applicable methods.
        #
        # options[:crud_type] should be a CRUD verb (:create, :read, :update, :destroy)
        # options[:column] should be the name of a model attribute
        # options[:action] is the name of a method
        # options[:reason] returns [authorized, reason], where reason may be nil
        def authorized_for?(options = {})
          if options[:crud_type] && %i[create read update delete].exclude?(options[:crud_type])
            raise ArgumentError, "unknown crud type #{options[:crud_type]}"
          end

          # collect other possibly-related methods that actually exist
          methods = cached_authorized_for_methods(options)
          return authorization_response(ActiveRecordPermissions.default_permission, nil, options[:reason]) if methods.empty?

          # if any method returns false, then return false
          methods.each do |method|
            authorized, reason = authorization_result(send(method))
            next if authorized

            return authorization_response(authorized, reason, options[:reason])
          end

          authorization_response(true, nil, options[:reason])
        end

        private

        def authorization_result(result)
          if ActiveRecordPermissions.not_authorized_reason && result.is_a?(String)
            [false, result]
          else
            [result, nil]
          end
        end

        # return array with reason only if requested
        def authorization_response(authorized, reason, include_reason)
          include_reason ? [authorized, reason] : authorized
        end

        def cached_authorized_for_methods(options)
          key = "#{options[:crud_type]}##{options[:column]}##{options[:action]}"
          if is_a? Class
            self.class_security_methods ||= {}
            class_security_methods[key] ||= authorized_for_methods(options)
          else
            self.class.instance_security_methods ||= {}
            self.class.instance_security_methods[key] ||= authorized_for_methods(options)
          end
        end

        def authorized_for_methods(options)
          # column_authorized_for_crud_type? has the highest priority over other methods,
          # you can disable a crud verb and enable that verb for a column
          # (for example, disable update and enable inplace_edit in a column)
          method = column_and_crud_type_security_method(options[:column], options[:crud_type])
          return [method] if method && respond_to?(method, true)

          # authorized_for_action? has higher priority than other methods,
          # you can disable a crud verb and enable an action with that crud verb
          # (for example, disable update and enable an action with update as crud type)
          method = action_security_method(options[:action])
          return [method] if method && respond_to?(method, true)

          # collect other possibly-related methods that actually exist
          [
            column_security_method(options[:column]),
            crud_type_security_method(options[:crud_type])
          ].compact.select { |m| respond_to?(m, true) }
        end

        def column_security_method(column)
          "#{column}_authorized?" if column
        end

        def crud_type_security_method(crud_type)
          "authorized_for_#{crud_type}?" if crud_type
        end

        def action_security_method(action)
          "authorized_for_#{action}?" if action
        end

        def column_and_crud_type_security_method(column, crud_type)
          "#{column}_authorized_for_#{crud_type}?" if column && crud_type
        end
      end
    end
  end
end
