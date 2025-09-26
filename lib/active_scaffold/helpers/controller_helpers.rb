# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    module ControllerHelpers
      def self.included(controller)
        return unless controller.respond_to? :helper_method

        controller.class_eval do
          helper_method :params_for, :conditions_from_params, :render_parent?,
                        :main_path_to_return, :render_parent_options,
                        :render_parent_action, :nested_singular_association?,
                        :main_form_controller, :build_associated,
                        :generate_temporary_id, :generated_id,
                        :active_scaffold_config_for, :tabbed_by_association
        end
      end

      include ActiveScaffold::Helpers::IdHelpers

      def active_scaffold_config_for(klass)
        config = self.class.active_scaffold_config_for(klass)
        config.user || config.new_user_settings({}, {})
      end

      def generate_temporary_id(record = nil, generated_id = nil)
        unless generated_id
          temp_id = (Time.now.to_f * 1_000_000).to_i.to_s
          temp_id.succ! while @temporary_ids&.dig(record.class.name)&.include?(temp_id)
          generated_id = temp_id
        end
        cache_generated_id record, generated_id
        generated_id
      end

      def cache_generated_id(record, generated_id)
        # cache all generated ids for the same class, so generate_temporary_id can check and ensure ids are unique
        ((@temporary_ids ||= {})[record.class.name] ||= []) << generated_id if record && generated_id
      end

      def generated_id(record)
        @temporary_ids[record.class.name]&.last if record && @temporary_ids
      end

      # These params should not propagate:
      # :adapter and :position are one-use rendering arguments.
      # :sort, :sort_direction, and :page are arguments that stored in the session, if store_user_settings is enabled
      # and wow. no we don't want to propagate :record.
      # :commit is a special rails variable for form buttons
      # :_method is a special rails variable to simulate put, patch and delete actions.
      # :dont_close is submit button which avoids closing form.
      # :auto_pagination is used when all records are loaded automatically with multiple request.
      # :iframe is used to simulate ajax forms loading form in iframe.
      # :associated_id used in add_existing
      # :authenticity_token is sent on some ajax requests
      # :_added is sent on checkbox-list with update_columns
      # :_removed is sent on checkbox-list with update_columns
      # :_popstate sent when loading previous page from history, after using history.pushState
      # :_ jQuery param added for GET requests with cache disabled
      BLACKLIST_PARAMS = %i[adapter position sort sort_direction page record commit _method dont_close auto_pagination
                            iframe associated_id authenticity_token _added _removed _popstate _].freeze

      def params_for(options = {})
        unless @params_for
          @params_for = {}
          params.except(*BLACKLIST_PARAMS).each do |key, value|
            @params_for[key.to_sym] = copy_param(value)
          end
          @params_for[:controller] = "/#{@params_for[:controller]}" unless @params_for[:controller]&.first(1) == '/' # for namespaced controllers
          @params_for.delete(:id) if @params_for[:id].nil?
        end

        url_options = @params_for.merge(options)
        if !active_scaffold_config.store_user_settings && controller_requested(url_options[:controller]) == controller_path
          url_options[:search] ||= copy_param search_params if respond_to?(:search_params, true) && search_params.present?
          url_options[:page] ||= params[:page]
          if active_scaffold_config.actions.include?(:list) && active_scaffold_config.list.user.user_sorting?
            column, direction = active_scaffold_config.list.user.sorting.first
            url_options[:sort] ||= column.name
            url_options[:sort_direction] ||= direction
          end
        end
        url_options
      end

      def controller_requested(controller)
        if controller.to_s.first(1) == '/'
          controller[1..]
        else
          path = controller_path.split('/')[0..-2]
          path << controller
          path.join('/')
        end
      end

      def copy_param(value)
        if controller_params? value
          params_hash value
        else
          value.duplicable? ? value.clone : value
        end
      end

      # Parameters to generate url to the main page (override if the ActiveScaffold is used as a component on another controllers page)
      def main_path_to_return
        if params[:return_to]
          params[:return_to]
        else
          exclude_parameters = %i[utf8 associated_id]
          parameters = {}
          if params[:parent_scaffold] && nested_singular_association?
            parameters[:controller] = params[:parent_scaffold]
            exclude_parameters.push nested.param_name, :association, :parent_scaffold
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

      def main_form_controller
        parent_controller_name.constantize if params[:parent_controller]
      end

      def render_parent?
        nested_singular_association? || params[:parent_sti]
      end

      def render_parent_options
        if nested_singular_association?
          {controller: nested.parent_scaffold.controller_path, action: :index, id: nested.parent_id}
        elsif parent_sti_controller
          options = params_for(controller: parent_sti_controller.controller_path, action: render_parent_action, parent_sti: nil)
          options.merge!(action: :index, id: @record.to_param) if render_parent_action == :row
          options
        end
      end

      def render_parent_action
        if @parent_action.nil?
          @parent_action = :row
          if parent_sti_controller
            parent_sti_config = parent_sti_controller.active_scaffold_config
            @parent_action = :index if action_name == 'create' && parent_sti_config.actions.include?(:create) && parent_sti_config.create.refresh_list == true
            @parent_action = :index if action_name == 'update' && parent_sti_config.actions.include?(:update) && parent_sti_config.update.refresh_list == true
            @parent_action = :index if action_name == 'destroy' && parent_sti_config.actions.include?(:delete) && parent_sti_config.delete.refresh_list == true
          end
        end
        @parent_action
      end

      def tabbed_by_association(assoc_column, tabbed_by)
        assoc_column.association.klass.reflect_on_association(tabbed_by)
      end

      # build an associated record for association
      def build_associated(association, parent_record)
        if association.through? && association.through_reflection.collection?
          # build full chain, only check create_associated on initial parent_record
          parent_record = build_associated(association.class.new(association.through_reflection), parent_record)
          source_assoc = association.class.new(association.source_reflection)
          build_associated(source_assoc, parent_record).tap do |record|
            save_record_to_association(record, source_assoc.reverse_association, parent_record) # set inverse
          end
        elsif association.through? # through belongs_to/has_one
          parent_record = parent_record.send(association.through_reflection.name)
          source_assoc = association.class.new(association.source_reflection)
          build_associated(source_assoc, parent_record)
        elsif association.collection?
          parent_record.send(association.name).build
        elsif association.belongs_to? || parent_record.new_record? || parent_record.send(association.name).nil?
          # avoid use build_association in has_one when record is saved and had associated record
          # because associated record would be changed in DB
          parent_record.send(:"build_#{association.name}")
        else
          association.klass.new.tap do |record|
            assign_default_attributes record
            save_record_to_association(record, association.reverse_association, parent_record) # set inverse
          end
        end.tap { |record| yield record if block_given? }
      end

      def save_record_to_association(record, association, value, reverse = nil)
        return unless association

        if association.collection?
          record.association(association.name).target << value
        elsif reverse&.belongs_to?
          value.send(:"#{reverse.name}=", record)
        else
          record.send(:"#{association.name}=", value)
        end
      end
    end
  end
end
