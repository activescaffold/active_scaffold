module ActiveScaffold::Actions
  # The Nested module basically handles automatically linking controllers together. It does this by creating column links with the right parameters, and by providing any supporting systems (like a /:controller/nested action for returning associated scaffolds).
  module Nested

    def self.included(base)
      super
      base.module_eval do
        before_filter :register_constraints_with_action_columns
        before_filter :set_nested
        before_filter :configure_nested
        include ActiveScaffold::Actions::Nested::ChildMethods if active_scaffold_config.model.reflect_on_all_associations.any? {|a| a.macro == :has_and_belongs_to_many}
      end
      base.before_filter :include_habtm_actions
      base.helper_method :nested
      base.helper_method :nested_parent_record
    end

    protected
    def nested
      @nested ||= ActiveScaffold::DataStructures::NestedInfo.get(active_scaffold_config.model, active_scaffold_session_storage)
      if !@nested.nil? && @nested.new_instance?
        register_constraints_with_action_columns(@nested.constrained_fields)
        active_scaffold_constraints[:id] = params[:id] if @nested.belongs_to?
      end
      @nested
    end
    
    def nested?
      !nested.nil?
    end
    
    def set_nested
      if params[:parent_scaffold] && ((params[:association] && params[:assoc_id]) || params[:named_scope])
        @nested = nil
        active_scaffold_session_storage[:nested] = {:parent_scaffold => params[:parent_scaffold].to_s,
                                                                  :name => (params[:association] || params[:named_scope]).to_sym,
                                                                  :parent_id => params[:assoc_id]}
        params.delete_if {|key, value| [:parent_scaffold, :association, :named_scope, :assoc_id].include? key.to_sym}
      end
    end
    
    def configure_nested
      if nested?
        active_scaffold_session_storage[:list][:label] =  if nested.belongs_to?
          as_(:nested_of_model, :nested_model => active_scaffold_config.model.model_name.human, :parent_model => nested_parent_record.to_label)
        else
          as_(:nested_for_model, :nested_model => active_scaffold_config.list.label, :parent_model => nested_parent_record.to_label)
        end
        if nested.sorted?
          active_scaffold_config.list.user.nested_default_sorting = {:table_name => active_scaffold_config.model.model_name, :default_sorting => nested.default_sorting}
        end
      end
    end
    
    def nested_authorized?(record = nil)
      true
    end

    def include_habtm_actions
      if nested?
        if nested.habtm?
          # Production mode is ok with adding a link everytime the scaffold is nested - we ar not ok with that.
          active_scaffold_config.action_links.add('new_existing', :label => :add_existing, :type => :collection, :security_method => :add_existing_authorized?) unless active_scaffold_config.action_links['new_existing']
          if active_scaffold_config.nested.shallow_delete
            active_scaffold_config.action_links.add('destroy_existing', :label => :remove, :type => :member, :confirm => :are_you_sure_to_delete, :method => :delete, :position => false, :security_method => :delete_existing_authorized?) unless active_scaffold_config.action_links['destroy_existing']
            if active_scaffold_config.actions.include?(:delete)
              active_scaffold_config.action_links.delete("delete") if active_scaffold_config.action_links['delete']
            end
          end
        else
          # Production mode is caching this link into a non nested scaffold
          active_scaffold_config.action_links.delete('new_existing') if active_scaffold_config.action_links['new_existing']
          
          if active_scaffold_config.nested.shallow_delete
            active_scaffold_config.action_links.delete("destroy_existing") if active_scaffold_config.action_links['destroy_existing']
            if active_scaffold_config.actions.include?(:delete)
              active_scaffold_config.action_links.add(ActiveScaffold::Config::Delete.link) unless active_scaffold_config.action_links['delete']
            end
          end
        end
      end
    end
    
    def beginning_of_chain
      if nested? && nested.association && nested.association.collection?
        nested.parent_scope.send(nested.association.name)
      elsif nested? && nested.scope
        nested.parent_scope.send(nested.scope)
      else
        active_scaffold_config.model
      end
    end

    def nested_parent_record(crud = :read)
      @nested_parent_record ||= find_if_allowed(nested.parent_id, crud, nested.parent_model)
    end
       
    def create_association_with_parent(record)
      if nested?
        if (nested.belongs_to? || nested.has_one? || nested.habtm?) && nested.child_association
          parent = nested_parent_record(:read)
          case nested.child_association.macro
          when :has_one
            record.send("#{nested.child_association.name}=", parent)
          when :belongs_to
            record.send("#{nested.child_association.name}=", parent)
          when :has_many, :has_and_belongs_to_many
            record.send("#{nested.child_association.name}").send(:<<, parent)
          end unless parent.nil?
        end
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
      base.verify :method => :post,
                  :only => :add_existing,
                  :redirect_to => { :action => :index }
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
      return redirect_to(params.merge(:action => :delete)) if request.get?
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
        flash[:info] = as_(:created_model, :model => @record.to_label)
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
      render :xml => response_object.to_xml(:only => active_scaffold_config.list.columns.names), :content_type => Mime::XML, :status => response_status
    end
    def add_existing_respond_to_json
      render :text => response_object.to_json(:only => active_scaffold_config.list.columns.names), :content_type => Mime::JSON, :status => response_status
    end
    def add_existing_respond_to_yaml
      render :text => Hash.from_xml(response_object.to_xml(:only => active_scaffold_config.list.columns.names)).to_yaml, :content_type => Mime::YAML, :status => response_status
    end
    def destroy_existing_respond_to_html
      flash[:info] = as_(:deleted_model, :model => @record.to_label)
      return_to_main
    end

    def destroy_existing_respond_to_js
      render(:action => 'destroy')
    end

    def destroy_existing_respond_to_xml
      render :xml => successful? ? "" : response_object.to_xml(:only => active_scaffold_config.list.columns.names), :content_type => Mime::XML, :status => response_status
    end

    def destroy_existing_respond_to_json
      render :text => successful? ? "" : response_object.to_json(:only => active_scaffold_config.list.columns.names), :content_type => Mime::JSON, :status => response_status
    end

    def destroy_existing_respond_to_yaml
      render :text => successful? ? "" : Hash.from_xml(response_object.to_xml(:only => active_scaffold_config.list.columns.names)).to_yaml, :content_type => Mime::YAML, :status => response_status
    end

    def add_existing_authorized?(record = nil)
      true
    end
    def delete_existing_authorized?(record = nil)
      true
    end
 
    def after_create_save(record)
      if params[:association_macro] == :has_and_belongs_to_many
        params[:associated_id] = record
        do_add_existing
      end
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
