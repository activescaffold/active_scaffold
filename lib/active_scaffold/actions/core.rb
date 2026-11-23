# frozen_string_literal: true

require 'active_scaffold/actions/core/render_field'
require 'active_scaffold/actions/core/record_building'
require 'active_scaffold/actions/core/controller_support'
require 'active_scaffold/actions/core/responding'
require 'active_scaffold/actions/core/action_link_handling'

module ActiveScaffold::Actions
  module Core
    def self.included(base)
      base.class_eval do
        before_action :verify_return_to_parameter
        before_action :set_vary_accept_header
        before_action :check_input_device
        before_action :register_constraints_with_action_columns, unless: :nested?
        after_action :clear_flashes
        after_action :dl_cookie
        around_action :clear_storage
        rescue_from ActiveScaffold::RecordNotAllowed, ActiveScaffold::ActionNotAllowed, with: :deny_access
      end
      base.helper_method :active_scaffold_config
      base.helper_method :successful?
      base.helper_method :nested?
      base.helper_method :grouped_search?
      base.helper_method :embedded?
      base.helper_method :loading_embedded?
      base.helper_method :calculate_query
      base.helper_method :calculate_subquery
      base.helper_method :new_model
      base.helper_method :touch_device?
      base.helper_method :hover_via_click?
    end

    include RenderField
    include RecordBuilding
    include ControllerSupport
    include Responding
    include ActionLinkHandling

    protected

    def filtered_query
      beginning_of_chain
    end

    # Override this method on the controller to provide a model with named scopes.
    def beginning_of_chain
      active_scaffold_config.model
    end

    def associated_record_scope(klass, column: nil)
      klass
    end

    private

    def look_for_parent_sti_controller
      klass = self.class.active_scaffold_config.model
      loop do
        klass = klass.superclass
        controller = self.class.active_scaffold_controller_for(klass)
        cfg = controller.active_scaffold_config if controller.uses_active_scaffold?
        next unless cfg&.add_sti_create_links?

        model_name = self.class.active_scaffold_config.model.name.underscore
        return controller if cfg.sti_children.map(&:to_s).include? model_name
      end
    rescue ActiveScaffold::ControllerNotFound => e
      logger.warn "#{e.message} looking for parent_sti of #{self.class.active_scaffold_config.model.name}"
      nil
    end
  end
end
