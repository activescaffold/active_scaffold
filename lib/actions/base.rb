module ActiveScaffold::Actions
  # every action gets basic security control for free. this is accomplished by
  # placing a before_filter on each public method of the action which calls a
  # method that can be overwritten by the developer to enable security controls.
  # the method is named #{action}_authorized?, and by default returns true.
  # we also filter params[:record] on a per-action basis, as applicable.
  module Base
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def included(base)
        action_name = self.to_s.sub(/(.*::)+/, '')
        action = action_name.underscore
        config = base.active_scaffold_config
        action_config = config.send(action.to_sym)

        # overall action security: check controller.#{action}_authorized?
        security_method = :"#{action}_authorized?"
        base.send(:define_method, security_method) {true}
        base.send :before_filter, security_method, :only => self.public_instance_methods(false)

        # per-column (per-action) security: record which columns are not allowed for this user and this action. this will make columns.[] and columns.each operate securely for this action.
        base.send :before_filter, proc { |controller|
          current_user = controller.send(config.current_user_method) rescue nil
          config.columns.create_blacklist(current_user, action)
        }, :only => self.public_instance_methods(false)
      end
    end
  end
end