module ActiveScaffold::Actions
  # The Nested module basically handles automatically linking controllers together. It does this by creating column links with the right parameters, and by providing any supporting systems (like a /:controller/nested action for returning associated scaffolds).
  module Nested
    def self.included(base)
      super
      base.module_eval do
        before_filter :set_nested
        before_filter :configure_nested
        include ActiveScaffold::Actions::Nested::ChildMethods if active_scaffold_config.model.reflect_on_all_associations.any? { |a| a.macro == :has_and_belongs_to_many }
      end
      base.before_filter :include_habtm_actions
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
      return unless params[:parent_scaffold] && (params[:association] || params[:named_scope])
      @nested = ActiveScaffold::DataStructures::NestedInfo.get(active_scaffold_config.model, params)
      register_constraints_with_action_columns(@nested.constrained_fields) unless @nested.nil?
    end

    def configure_nested
      return unless nested?
      active_scaffold_config.list.user.label = nested_label
      active_scaffold_config.list.user.nested_default_sorting = nested_default_sorting if nested.sorted? && !active_scaffold_config.nested.ignore_order_from_association
    end

    def nested_label
      if nested.belongs_to?
        as_(:nested_of_model, :nested_model => active_scaffold_config.model.model_name.human, :parent_model => ERB::Util.h(nested_parent_record.to_label))
      else
        as_(:nested_for_model, :nested_model => active_scaffold_config.list.label, :parent_model => ERB::Util.h(nested_parent_record.to_label))
      end
    end

    def nested_default_sorting
      {:table_name => active_scaffold_config.model.model_name, :default_sorting => nested.default_sorting}
    end

    def nested_authorized?(record = nil)
      true
    end

    def include_habtm_actions
      if nested? && nested.habtm?
        # Production mode is ok with adding a link everytime the scaffold is nested - we are not ok with that.
        active_scaffold_config.action_links.add('new_existing', :label => :add_existing, :type => :collection, :security_method => :add_existing_authorized?) unless active_scaffold_config.action_links['new_existing']
        if active_scaffold_config.nested.shallow_delete
          active_scaffold_config.action_links.add('destroy_existing', :label => :remove, :type => :member, :confirm => :are_you_sure_to_delete, :method => :delete, :position => false, :security_method => :delete_existing_authorized?) unless active_scaffold_config.action_links['destroy_existing']
          if active_scaffold_config.actions.include?(:delete)
            active_scaffold_config.action_links.delete('delete') if active_scaffold_config.action_links['delete']
          end
        end
      else
        # Production mode is caching this link into a non nested scaffold
        active_scaffold_config.action_links.delete('new_existing') if active_scaffold_config.action_links['new_existing']

        if active_scaffold_config.nested.shallow_delete
          active_scaffold_config.action_links.delete('destroy_existing') if active_scaffold_config.action_links['destroy_existing']
          if active_scaffold_config.actions.include?(:delete) && active_scaffold_config.delete.link
            active_scaffold_config.action_links.add(active_scaffold_config.delete.link) unless active_scaffold_config.action_links['delete']
          end
        end
      end
    end

    def beginning_of_chain
      if nested? && nested.association
        if nested.association.collection?
          nested_parent_record.send(nested.association.name)
        elsif nested.association.options[:through] # has_one :through
          active_scaffold_config.model.where(active_scaffold_config.model.primary_key => nested_parent_record.send(nested.association.name).try(:id))
        elsif nested.child_association.nil? # without child_association is not possible to add conditions
          active_scaffold_config.model
        elsif nested.child_association.belongs_to?
          active_scaffold_config.model.where(nested.child_association.foreign_key => nested_parent_record.send(nested.association.association_primary_key))
        elsif nested.association.belongs_to?
          chain = active_scaffold_config.model.joins(nested.child_association.name)
          table_name =
            if active_scaffold_config.model == nested.association.active_record
              dependency = ActiveRecord::Associations::JoinDependency.new(chain.klass, chain.joins_values, [])
              join_associations = Rails.version >= '4.1.0' ? dependency.join_root.children : dependency.join_associations
              join_associations.find {|join| join.try(:reflection).try(:name) == nested.child_association.name}.try(:table).try(:right)
            end
          table_name ||= nested.association.active_record.table_name
          chain.where(table_name => {nested.association.active_record.primary_key => nested_parent_record}).readonly(false)
        end
      elsif nested? && nested.scope
        nested_parent_record.send(nested.scope)
      else
        active_scaffold_config.model
      end
    end

    def nested_parent_record(crud = :read)
      @nested_parent_record ||= find_if_allowed(nested.parent_id, crud, nested.parent_model)
    end

    def create_association_with_parent(record)
      # has_many is done by beginning_of_chain and rails
      return unless (nested.belongs_to? || nested.has_one? || nested.habtm?) && nested.child_association
      return if (parent = nested_parent_record).nil?
      case nested.child_association.macro
      when :has_one, :belongs_to
        record.send("#{nested.child_association.name}=", parent)
      when :has_many, :has_and_belongs_to_many
        record.send("#{nested.child_association.name}").send(:<<, parent)
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
      return redirect_to(params.merge(:action => :delete, :only_path => true)) if request.get?
      do_destroy_existing
      respond_to_action(:destroy_existing)
    end

    protected

    def new_existing_respond_to_html
      if successful?
        render(:action => 'add_existing_form')
      else
        return_to_main
      end
    end

    def new_existing_respond_to_js
      render(:partial => 'add_existing_form')
    end

    def add_existing_respond_to_html
      if successful?
        flash[:info] = as_(:created_model, :model => ERB::Util.h(@record.to_label))
        return_to_main
      else
        render(:action => 'add_existing_form')
      end
    end

    def add_existing_respond_to_js
      if successful?
        render :action => 'add_existing'
      else
        render :action => 'form_messages'
      end
    end

    def add_existing_respond_to_xml
      render :xml => response_object, :only => active_scaffold_config.list.columns.names, :status => response_status
    end

    def add_existing_respond_to_json
      render :json => response_object, :only => active_scaffold_config.list.columns.names, :status => response_status
    end

    def destroy_existing_respond_to_html
      flash[:info] = as_(:deleted_model, :model => ERB::Util.h(@record.to_label))
      return_to_main
    end

    def destroy_existing_respond_to_js
      render(:action => 'destroy')
    end

    def destroy_existing_respond_to_xml
      render :xml => successful? ? '' : response_object, :only => active_scaffold_config.list.columns.names, :status => response_status
    end

    def destroy_existing_respond_to_json
      render :json => successful? ? '' : response_object, :only => active_scaffold_config.list.columns.names, :status => response_status
    end

    def add_existing_authorized?(record = nil)
      nested_parent_record.authorized_for?(:crud_type => :update, :column => nested.association.try(:name))
    end

    def delete_existing_authorized?(record = nil)
      nested_parent_record.authorized_for?(:crud_type => :update, :column => nested.association.try(:name))
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
        parent_record.send(nested.association.name) << @record
        parent_record.save
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
