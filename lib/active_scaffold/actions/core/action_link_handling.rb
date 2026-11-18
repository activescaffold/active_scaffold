# frozen_string_literal: true

module ActiveScaffold::Actions
  module Core
    module ActionLinkHandling
      protected

      # Call this method in an action-link action to handle confirmation, authorization, and response dispatch.
      def process_action_link_action(render_action = :action_update, crud_type_or_security_options = nil, &)
        if request.get? || request.head?
          @record = find_if_allowed(params[:id], :read) if params[:id]
          respond_to_action(:action_confirmation)
        else
          @action_link = active_scaffold_config.action_links[action_name]
          load_action_link_record(crud_type_or_security_options)
          raise ActiveScaffold::ActionNotAllowed unless action_link_authorized? @action_link, @record

          invoke_action_link(&)
          respond_to_action(render_action)
        end
      end

      def load_action_link_record(crud_type_or_security_options)
        return unless params[:id]

        crud_type_or_security_options ||= {
          crud_type: request.delete? ? :delete : :update,
          action: action_name
        }
        get_row(crud_type_or_security_options)
      end

      def invoke_action_link
        if params[:id]
          if @record.nil?
            self.successful = false
            flash[:error] = as_(:no_authorization_for_action, action: @action_link&.label(nil) || action_name)
          else
            yield @record
          end
        else
          yield
        end
      end

      def action_link_authorized?(link, record = nil)
        link&.security_method.nil? || !respond_to?(link.security_method, true) ||
          Array(send(link.security_method, *record))[0]
      end

      def action_confirmation_respond_to_html(confirm_action = action_name.to_sym)
        link = active_scaffold_config.action_links[confirm_action]
        render action: 'action_confirmation', locals: {record: @record, link: link}
      end

      def action_update_respond_on_iframe
        responds_to_parent { action_update_respond_to_js }
      end

      def action_update_respond_to_html
        redirect_to action: 'index'
      end

      def action_update_respond_to_js
        render action: 'on_action_update', formats: [:js], layout: false
      end

      def action_update_respond_to_xml
        response_to_api(:xml, list_columns_names)
      end

      def action_update_respond_to_json
        response_to_api(:json, list_columns_names)
      end
    end
  end
end
