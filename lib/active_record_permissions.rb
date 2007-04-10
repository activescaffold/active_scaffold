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
module ActiveRecordPermissions
  # ActiveRecordPermissions needs to know what method on your ApplicationController will return the current user,
  # if available. This defaults to the :current_user method. You may configure this in your environment.rb if you
  # have a different setup.
  def self.current_user_method=(v); @@current_user_method = v; end
  def self.current_user_method; @@current_user_method; end
  @@current_user_method = :current_user

  # Whether the default permission is permissive or not
  # If set to true, then everything's allowed until configured otherwise
  def self.default_permission=(v); @@default_permission = v; end
  def self.default_permission; @@default_permission; end
  @@default_permission = true

  # This is a module aimed at making the current_user available to ActiveRecord models for permissions.
  module ModelUserAccess
    module Controller
      def self.included(base)
        base.prepend_before_filter :assign_current_user_to_models
      end

      # We need to give the ActiveRecord classes a handle to the current user. We don't want to just pass the object,
      # because the object may change (someone may log in or out). So we give ActiveRecord a proc that ties to the
      # current_user_method on this ApplicationController.
      def assign_current_user_to_models
        ActiveRecord::Base.current_user_proc = proc {send(ActiveRecordPermissions.current_user_method)}
      end
    end

    module Model
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # The proc to call that retrieves the current_user from the ApplicationController.
        attr_accessor :current_user_proc

        # Class-level access to the current user [is this useful?]
        def current_user
          ActiveRecord::Base.current_user_proc.call
        end
      end

      # Instance-level access to the current user
      def current_user
        self.class.current_user
      end
    end
  end

  module Permissions
    def self.included(base)
      base.extend ClassMethods
    end

    # A generic authorization query. This is what will be called programatically, since
    # the actual permission methods can't be guaranteed to exist. And because we want to
    # intelligently combine multiple applicable methods.
    #
    # options[:action] should be a CRUD verb (:create, :read, :update, :destroy)
    def authorized_for?(options = {})
      options.assert_valid_keys :action, :column
      raise ArgumentError, "unknown action #{options[:action]}" if options[:action] and ![:create, :read, :update, :destroy].include?(options[:action])

      methods = [
        column_security_method(options[:column]),
        action_security_method(options[:action]),
        column_and_action_security_method(options[:column], options[:action])
      ].compact

      # if any method actually exists and returns false, then return false
      return false if methods.any? {|m| respond_to?(m) and !send(m)}

      # if any method actually exists then it must've returned true, so return true
      return true if methods.any? {|m| respond_to?(m)}

      # if no method exists, return the default permission
      return ActiveRecordPermissions.default_permission
    end

    module ClassMethods
      # Class level just delegates to instance level
      def authorized_for?(*args)
        self.new.authorized_for?(*args)
      end
    end

    private

    def column_security_method(column)
      "#{column}_authorized?" if column
    end

    def action_security_method(action)
      "authorized_for_#{action}?" if action
    end

    def column_and_action_security_method(column, action)
      "#{column}_authorized_for_#{action}?" if column and action
    end
  end
end

ActionController::Base.class_eval {include ActiveRecordPermissions::ModelUserAccess::Controller}
ActiveRecord::Base.class_eval {include ActiveRecordPermissions::ModelUserAccess::Model}
ActiveRecord::Base.class_eval {include ActiveRecordPermissions::Permissions}