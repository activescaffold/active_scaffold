module ActiveScaffold
  module Helpers
    module ControllerHelpers
      def self.included(controller)
        controller.class_eval { helper_method :params_for, :main_path_to_return, :render_parent?, :render_parent_options, :render_parent_action, :nested_singular_association?}
      end
      
      include ActiveScaffold::Helpers::IdHelpers
      
      def params_for(options = {})
        # :adapter and :position are one-use rendering arguments. they should not propagate.
        # :sort, :sort_direction, and :page are arguments that stored in the session. they need not propagate.
        # and wow. no we don't want to propagate :record.
        # :commit is a special rails variable for form buttons
        blacklist = [:adapter, :position, :sort, :sort_direction, :page, :record, :commit, :_method, :authenticity_token, :iframe]
        unless @params_for
          @params_for = {}
          params.select { |key, value| blacklist.exclude? key.to_sym if key }.each {|key, value| @params_for[key.to_sym] = value.duplicable? ? value.clone : value}
          @params_for[:controller] = '/' + @params_for[:controller].to_s unless @params_for[:controller].to_s.first(1) == '/' # for namespaced controllers
          @params_for.delete(:id) if @params_for[:id].nil?
        end
        @params_for.merge(options)
      end

      # Parameters to generate url to the main page (override if the ActiveScaffold is used as a component on another controllers page)
      def main_path_to_return
        if params[:return_to]
          params[:return_to]
        else
          parameters = {}
          if params[:parent_controller]
            parameters[:controller] = params[:parent_controller]
            parameters[:eid] = params[:parent_controller]
          end
          if nested?
            parameters[:controller] = nested.parent_scaffold.controller_path
            parameters[:eid] = nil
          end
          if params[:parent_sti]
            parameters[:controller] = params[:parent_sti]
            parameters[:eid] = nil
          end
          parameters[:parent_column] = nil
          parameters[:parent_id] = nil
          parameters[:action] = "index"
          parameters[:id] = nil
          parameters[:associated_id] = nil
          parameters[:utf8] = nil
          params_for(parameters)
        end
      end

      def nested_singular_association?
        nested? && (nested.belongs_to? || nested.has_one?)
      end

      def render_parent?
        nested_singular_association? || params[:parent_sti]
      end

      def render_parent_options
        if nested_singular_association?
          {:controller => nested.parent_scaffold.controller_path, :action => :row, :id => nested.parent_id}
        elsif params[:parent_sti]
          options = {:controller => params[:parent_sti], :action => render_parent_action(params[:parent_sti])}
          if render_parent_action(params[:parent_sti]) == :index
            options.merge(params.slice(:eid))
          else
            options.merge({:id => @record.id})
          end
        end
      end

      def render_parent_action(controller_path = nil)
        begin
          @parent_action = :row
          parent_controller = "#{controller_path.to_s.camelize}Controller".constantize
          @parent_action = :index if action_name == 'create' && parent_controller.active_scaffold_config.actions.include?(:create) && parent_controller.active_scaffold_config.create.refresh_list == true
          @parent_action = :index if action_name == 'update' && parent_controller.active_scaffold_config.actions.include?(:update) && parent_controller.active_scaffold_config.update.refresh_list == true
          @parent_action = :index if action_name == 'destroy' && parent_controller.active_scaffold_config.actions.include?(:delete) && parent_controller.active_scaffold_config.delete.refresh_list == true
        rescue ActiveScaffold::ControllerNotFound
        end if @parent_action.nil?
        @parent_action
      end
    end
  end
end
