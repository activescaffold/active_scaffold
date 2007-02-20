module ActiveScaffold::Actions
  # every action gets basic security control for free. this is accomplished by placing a before_filter on each public method of the action which calls a method that can be overwritten by the developer to enable security controls. the method is named #{action}_authorized?, and by default returns true.
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

        # per-column (per-action) security: try to filter params[:record] so data can't sneak in
        base.send :before_filter, proc { |controller|
          if controller.params[:record]
            controller.params[:record].each do |index, value|
              ##
              ## sometimes the parameter doesn't match the column name. here we attempt a couple of rewrites:
              ##
              # first we deal with params like record[date_field(1i)]
              column_name = index.sub(/\([a-z0-9]+\)/, '')
              # then we check to see if this column is a primary_key_name for some association
              config.columns.each do |column|
                next unless column.association and column.association.primary_key_name.to_s == column_name
                column_name = column.name.to_s and break
              end

              ##
              ## then we verify that this column is registered for the action
              ##
              unless action_config.columns.include? column_name
                controller.logger.info "ActiveScaffold: params[:record][:#{index}] not found in column list (looked for #{column_name})"
                controller.params[:record].delete(index)
              end

              ##
              ## then we verify that the user is authorized to perform this action on this column
              ##
              begin
                config.columns[column_name.to_sym]
              rescue ActiveScaffold::ColumnNotAllowed
                controller.logger.info "ActiveScaffold: params[:record][:#{index}] not allowed for user"
                controller.params[:record].delete(index)
              end
            end
          end
        }, :only => self.public_instance_methods(false)
      end
    end
  end
end