module ActiveScaffold
  module Helpers
    module ControllerHelpers
      def self.included(controller)
        controller.class_eval { helper_method :params_for, :conditions_from_params, :main_path_to_return, :render_parent?, :render_parent_options, :render_parent_action, :nested_singular_association?, :build_associated, :generate_temporary_id, :generated_id }
      end

      include ActiveScaffold::Helpers::IdHelpers

      def generate_temporary_id(record = nil, generated_id = nil)
        (generated_id || (Time.now.to_f * 1000).to_i.to_s).tap do |id|
          (@temporary_ids ||= {})[record.class.name] = id if record
        end
      end

      def generated_id(record)
        @temporary_ids[record.class.name] if record && @temporary_ids
      end

      # These params should not propagate:
      # :adapter and :position are one-use rendering arguments.
      # :sort, :sort_direction, and :page are arguments that stored in the session.
      # and wow. no we don't want to propagate :record.
      # :commit is a special rails variable for form buttons
      # :_method is a special rails variable to simulate put, patch and delete actions.
      # :dont_close is submit button which avoids closing form.
      # :auto_pagination is used when all records are loaded automatically with multiple request.
      # :iframe is used to simulate ajax forms loading form in iframe.
      # :associated_id used in add_existing
      # :authenticity_token is sent on some ajax requests
      BLACKLIST_PARAMS = [:adapter, :position, :sort, :sort_direction, :page, :record, :commit, :_method, :dont_close, :auto_pagination, :iframe, :associated_id, :authenticity_token].freeze

      def params_for(options = {})
        unless @params_for
          @params_for = {}
          params.except(*BLACKLIST_PARAMS).each { |key, value| @params_for[key.to_sym] = value.duplicable? ? value.clone : value }
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
          exclude_parameters = [:utf8, :associated_id]
          parameters = {}
          if params[:parent_scaffold] && nested? && nested.singular_association?
            parameters[:controller] = params[:parent_scaffold]
            exclude_parameters.concat [nested.param_name, :association, :parent_scaffold]
            # parameters[:eid] = params[:parent_scaffold] # not neeeded anymore?
          end
          parameters.merge! nested.to_params if nested?
          if params[:parent_sti]
            parameters[:controller] = params[:parent_sti]
            # parameters[:eid] = nil # not neeeded anymore?
          end
          parameters[:action] = 'index'
          parameters[:id] = nil
          params_for(parameters).except(*exclude_parameters)
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
          {:controller => nested.parent_scaffold.controller_path, :action => :index, :id => nested.parent_id}
        elsif params[:parent_sti]
          options = params_for(:controller => params[:parent_sti], :action => render_parent_action, :parent_sti => nil)
          options.merge(:action => :index, :id => @record.to_param) if render_parent_action == :row
        end
      end

      def render_parent_action
        if @parent_action.nil?
          begin
            @parent_action = :row
            if params[:parent_sti]
              parent_controller = "#{params[:parent_sti].to_s.camelize}Controller".constantize
              @parent_action = :index if action_name == 'create' && parent_controller.active_scaffold_config.actions.include?(:create) && parent_controller.active_scaffold_config.create.refresh_list == true
              @parent_action = :index if action_name == 'update' && parent_controller.active_scaffold_config.actions.include?(:update) && parent_controller.active_scaffold_config.update.refresh_list == true
              @parent_action = :index if action_name == 'destroy' && parent_controller.active_scaffold_config.actions.include?(:delete) && parent_controller.active_scaffold_config.delete.refresh_list == true
            end
          rescue ActiveScaffold::ControllerNotFound => ex
            logger.warn "#{ex.message} for parent_sti #{params[:parent_sti]}"
          end
        end
        @parent_action
      end

      # build an associated record for association
      def build_associated(association, parent_record)
        if association.options[:through]
          # build full chain, only check create_associated on initial parent_record
          parent_record = build_associated(association.through_reflection, parent_record)
          build_associated(association.source_reflection, parent_record).tap do |record|
            save_record_to_association(record, association.source_reflection.reverse, parent_record) # set inverse
          end
        elsif association.collection?
          parent_record.send(association.name).build
        elsif association.belongs_to? || parent_record.new_record? || parent_record.send(association.name).nil?
          # avoid use build_association in has_one when record is saved and had associated record
          # because associated record would be changed in DB
          parent_record.send("build_#{association.name}")
        else
          association.klass.new.tap do |record|
            save_record_to_association(record, association.reverse, parent_record) # set inverse
          end
        end
      end
    end
  end
end
