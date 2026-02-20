# frozen_string_literal: true

module ActiveScaffold::Actions
  # The Nested module basically handles automatically linking controllers together.
  # It does this by creating column links with the right parameters, and by providing
  # any supporting systems (like a /:controller/nested action for returning associated scaffolds).
  module Nested
    def self.included(base)
      super
      base.module_eval do
        before_action :set_nested
        before_action :configure_nested
        include ActiveScaffold::Actions::Nested::ChildMethods if active_scaffold_config.columns.filter_map(&:association).any?(&:habtm?)
      end
      base.helper_method :nested
      base.helper_method :nested_parent_record
    end

    protected

    def nested
      set_nested unless defined? @nested
      @nested
    end

    def nested?
      !nested.nil?
    end

    def set_nested
      @nested = nil
      return unless params[:parent_scaffold] && (params[:association] || params[:named_scope])

      @nested = ActiveScaffold::DataStructures::NestedInfo.get(self.class.active_scaffold_config.model, params)
    end

    def configure_nested
      return unless nested?

      register_constraints_with_action_columns(nested.constrained_fields)
      return unless active_scaffold_config.actions.include? :list

      active_scaffold_config.list.user.label = nested_label
      return if active_scaffold_config.nested.ignore_order_from_association

      chain = beginning_of_chain
      active_scaffold_config.list.user.nested_default_sorting = nested_default_sorting(chain) if nested.sorted?(chain)
    end

    def nested_label
      if nested.belongs_to?
        as_(:nested_of_model, nested_model: active_scaffold_config.model.model_name.human, parent_model: ERB::Util.h(nested_parent_record.to_label))
      else
        as_(:nested_for_model, nested_model: active_scaffold_config.list.label, parent_model: ERB::Util.h(nested_parent_record.to_label))
      end
    end

    def nested_default_sorting(chain)
      {table_name: active_scaffold_config._table_name, default_sorting: nested.default_sorting(chain)}
    end

    def nested_authorized?(record = nil)
      true
    end

    def beginning_of_chain
      # only if nested is related to current controller, e.g. not when adding record in subform inside subform
      if nested? && nested.match_model?(active_scaffold_config.model)
        nested_chain_with_association
      elsif nested? && nested.scope
        nested_parent_record.send(nested.scope)
      else
        active_scaffold_config.model
      end
    end

    def nested_chain_with_association
      if nested.association.collection?
        nested_parent_record.send(nested.association.name)
      elsif nested.association.through? # has_one :through
        active_scaffold_config.model.where(active_scaffold_config.model.primary_key => nested_parent_record.send(nested.association.name)&.id)
      elsif nested.association.has_one?
        active_scaffold_config.model.where(nested.child_association.name => nested_parent_record)
      elsif nested.association.belongs_to?
        primary_key = active_scaffold_config.mongoid? ? '_id' : active_scaffold_config.model.primary_key
        active_scaffold_config.model.where(primary_key => nested_parent_record.send(nested.association.name))
      else # never should get here
        raise 'missing condition for nested beginning_of_chain'
      end
    end

    def nested_parent_record(crud = :read)
      @nested_parent_record ||= find_if_allowed(nested.parent_id, crud, nested.parent_model)
    end

    def create_association_with_parent?(check_match: false)
      # has_many is done by beginning_of_chain and rails if direct association, not in through associations
      return false unless nested.create_with_parent?
      return false if check_match && !nested.match_model?(active_scaffold_config.model)

      nested_parent_record.present?
    end

    def create_association_with_parent(record, check_match: false)
      return unless create_association_with_parent?(check_match: check_match)

      if nested.child_association&.singular?
        record.send(:"#{nested.child_association.name}=", nested_parent_record)
      elsif nested.create_through_singular?
        create_on_through_singular(record, nested.association, nested_parent_record)
      else
        record.send(nested.child_association.name) << nested_parent_record
      end
    end

    private

    def nested_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.nested.formats).uniq
    end
  end
end

module ActiveScaffold::Actions::Nested
  module ChildMethods
    def self.included(base)
      super
      include_habtm_actions base.active_scaffold_config unless base.active_scaffold_config.frozen?
    end

    def self.include_habtm_actions(config)
      # Production mode is ok with adding a link everytime the scaffold is nested - we are not ok with that.
      unless config.action_links['new_existing']
        config.action_links.add('new_existing', label: :add_existing, type: :collection,
                                                security_method: :add_existing_authorized?,
                                                ignore_method: :add_existing_ignore?)
      end
      return unless config.nested.shallow_delete

      unless config.action_links['destroy_existing']
        config.action_links.add('destroy_existing', label: :remove, type: :member, confirm: :are_you_sure_to_delete,
                                                    method: :delete, position: false,
                                                    security_method: :delete_existing_authorized?,
                                                    ignore_method: :delete_existing_ignore?)
      end
      config.action_links['destroy']&.ignore_method = :habtm_delete_ignore? if config.actions.include?(:delete)
    end

    def new_existing
      do_new
      respond_to_action(:new_existing)
    end

    def add_existing
      do_add_existing
      respond_to_action(:add_existing)
    end

    def destroy_existing
      return redirect_to(params.merge(action: :delete, only_path: true)) if request.get? || request.head?

      do_destroy_existing
      respond_to_action(:destroy_existing)
    end

    protected

    def new_existing_respond_to_html
      if successful?
        render action: 'add_existing_form'
      else
        return_to_main
      end
    end

    def new_existing_respond_to_js
      render partial: 'add_existing_form'
    end

    def add_existing_respond_to_html
      if successful?
        flash[:info] = as_(:created_model, model: ERB::Util.h(@record.to_label))
        return_to_main
      else
        render action: 'add_existing_form'
      end
    end

    def add_existing_respond_to_js
      if successful?
        render action: 'add_existing'
      else
        render action: 'form_messages'
      end
    end

    def add_existing_respond_to_xml
      render xml: response_object, only: active_scaffold_config.list.columns.visible_columns_names, status: response_status
    end

    def add_existing_respond_to_json
      render json: response_object, only: active_scaffold_config.list.columns.visible_columns_names, status: response_status
    end

    def destroy_existing_respond_to_html
      flash[:info] = as_(:deleted_model, model: ERB::Util.h(@record.to_label))
      return_to_main
    end

    def destroy_existing_respond_to_js
      render action: 'destroy'
    end

    def destroy_existing_respond_to_xml
      render xml: successful? ? '' : response_object, only: active_scaffold_config.list.columns.visible_columns_names, status: response_status
    end

    def destroy_existing_respond_to_json
      render json: successful? ? '' : response_object, only: active_scaffold_config.list.columns.visible_columns_names, status: response_status
    end

    def add_existing_authorized?(record = nil)
      nested_parent_record.authorized_for?(crud_type: :update, column: nested.association.try(:name))
    end

    def delete_existing_authorized?(record = nil)
      nested_parent_record.authorized_for?(crud_type: :update, column: nested.association.try(:name), reason: true)
    end

    def add_existing_ignore?(record = nil)
      !nested&.habtm?
    end

    def delete_existing_ignore?(record = nil)
      !nested&.habtm?
    end

    def habtm_delete_ignore?(record = nil)
      !delete_existing_ignore?(record) || delete_ignore?(record)
    end

    def after_create_save(record)
      return unless params[:association_macro] == :has_and_belongs_to_many

      params[:associated_id] = record
      do_add_existing
    end

    # The actual "add_existing" algorithm
    def do_add_existing
      parent_record = nested_parent_record(:update)
      @record = active_scaffold_config.model.find(params[:associated_id])
      if parent_record && @record
        self.successful = false unless parent_record.send(nested.association.name) << @record
        parent_record.save if successful?
      else
        false
      end
    end

    def do_destroy_existing
      if active_scaffold_config.nested.shallow_delete
        @record = nested_parent_record(:update)
        collection = @record.send(nested.association.name)
        assoc_record = collection.find(params[:id])
        collection.delete(assoc_record)
      else
        do_destroy
      end
    end

    private

    def new_existing_formats
      (default_formats + active_scaffold_config.formats).uniq
    end

    def add_existing_formats
      (default_formats + active_scaffold_config.formats).uniq
    end

    def destroy_existing_formats
      (default_formats + active_scaffold_config.formats).uniq
    end
  end
end
