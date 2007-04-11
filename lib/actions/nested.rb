module ActiveScaffold::Actions
  module Nested

    def self.included(base)
      super
      base.active_scaffold_config.list.columns.each do |column|
        column.set_link('nested', :parameters => {:associations => column.name.to_sym}) if column.association and column.link.nil? and column.plural_association?
      end
      base.before_filter :include_habtm_actions
    end

    def nested
      do_nested

      respond_to do |type|
        type.html { render :partial => 'nested', :layout => true }
        type.js { render :partial => 'nested', :layout => false }
      end
    end

    protected

    # A simple method to find the record we'll be nesting *from*
    # May be overridden to customize the behavior
    def do_nested
      @record = find_if_allowed(params[:id], :read)
    end

    def include_habtm_actions
      if nested_habtm?
        # Production mode is ok with adding a link everytime the scaffold is nested - we ar not ok with that.
        active_scaffold_config.action_links.add('new_existing', :label => as_('Add From Existing'), :type => :table, :security_method => :add_existing_authorized?) unless active_scaffold_config.action_links['new_existing']
        self.class.module_eval do
          include ActiveScaffold::Actions::Nested::ChildMethods
        end
      else
        # Production mode is caching this link into a non nested scaffold
        active_scaffold_config.action_links.delete('new_existing') if active_scaffold_config.action_links['new_existing']
      end
    end

    def nested?
      !params[:nested].nil?
    end

    def nested_habtm?
      begin
        return active_scaffold_config.columns[nested_association].association.macro == :has_and_belongs_to_many if nested?
        false
      rescue
        raise ActiveScaffold::MalformedConstraint, constraint_error(nested_association), caller
      end
    end

    def nested_association
      return active_scaffold_constraints.keys.to_s.to_sym if nested?
      nil
    end

    def nested_parent_id
      return active_scaffold_constraints.values.to_s if nested?
      nil
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

      respond_to do |type|
        type.html do
          if successful?
            render(:action => 'add_existing_form', :layout => true)
          else
            return_to_main
          end
        end
        type.js do
          render(:partial => 'add_existing_form', :layout => false)
        end
      end
    end

    def add_existing
      do_add_existing

      respond_to do |type|
        type.html do
          if successful?
            flash[:info] = as_('Created %s', @record.to_label)
            return_to_main
          else
            render(:action => 'add_existing_form', :layout => true)
          end
        end
        type.js do
          if successful?
            render :action => 'add_existing', :layout => false
          else
            render :action => 'form_messages.rjs', :layout => false
          end
        end
        type.xml { render :xml => response_object.to_xml, :content_type => Mime::XML, :status => response_status }
        type.json { render :text => response_object.to_json, :content_type => Mime::JSON, :status => response_status }
        type.yaml { render :text => response_object.to_yaml, :content_type => Mime::YAML, :status => response_status }
      end
    end

    protected

    def after_create_save(record)
      if params[:association_macro] == :has_and_belongs_to_many
        params[:associated_id] = record
        do_add_existing
      end
    end

    def nested_action_from_params
      return params[:parent_model].constantize, nested_parent_id, params[:parent_column]
    end

    # The actual "add_existing" algorithm
    def do_add_existing
      parent_model, id, association = nested_action_from_params
      parent_record = find_if_allowed(id, :update, parent_model)
      @record = active_scaffold_config.model.find(params[:associated_id])
      parent_record.send(association) << @record
      parent_record.save
    end

    def do_destroy_association
      parent_model, id, association = nested_action_from_params
      parent_record = find_if_allowed(id, :update, parent_model)
      @record = parent_record.send("roles").find(params[:id])
      @record.destroy
    end

  end
end
