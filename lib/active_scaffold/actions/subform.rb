# frozen_string_literal: true

module ActiveScaffold::Actions
  module Subform
    def edit_associated
      do_edit_associated
      respond_to do |format|
        format.js { render action: 'edit_associated', formats: [:js], readonly: @column.association.readonly? }
      end
    end

    protected

    def new_parent_record
      parent_record = new_model
      # don't apply if scope, subform inside subform, because constraints won't apply to parent_record
      apply_constraints_to_record parent_record unless @scope
      create_association_with_parent parent_record, check_match: true if nested?
      cache_generated_id(parent_record, params[:generated_id])
      parent_record
    end

    def do_edit_associated
      verify_tab_selection_parameters
      @scope = params[:scope]
      @parent_record = params[:id].nil? ? new_parent_record : find_if_allowed(params[:id], :update)
      @column = active_scaffold_config.columns[params[:child_association]]

      @record = (find_associated_record if params[:associated_id]) ||
                build_associated(@column.association, @parent_record) do |blank_record|
                  if params[:tabbed_by] && params[:value]
                    @tab_id = params.delete(:value)
                    assign_tabbed_by(blank_record, @column, params.delete(:tabbed_by), @tab_id, params.delete(:value_type))
                  end
                end
    end

    def verify_tab_selection_parameters
      return unless params.key?(:tabbed_by) || params.key?(:value_type) || params.key?(:tab_signature)

      payload = ActiveScaffold::ParameterSigning.tab_selection_payload(params, controller: controller_path)
      unless params[:tabbed_by].is_a?(String) && params[:value].is_a?(String) &&
             ActiveScaffold::ParameterSigning.valid_signature?(payload, params[:tab_signature], purpose: :tab_selection)
        raise ::ActionController::BadRequest, 'Invalid tab selection signature'
      end

      params.delete(:tab_signature)
    end

    def assign_tabbed_by(record, parent_column, tabbed_by, value, value_type)
      if (association = tabbed_by_association(parent_column, tabbed_by))
        klass =
          if association.polymorphic?
            raise ::ActionController::BadRequest if value_type.blank?

            value_type.constantize
          else
            association.klass
          end
      end
      record.send :"#{tabbed_by}=", klass&.find(value) || value
    end

    def find_associated_record
      scope = associated_record_scope(@column.association.klass, column: @column)
      find_if_allowed(params[:associated_id], :read, scope).tap do |record|
        save_record_to_association(record, @column.association.reverse_association, @parent_record, @column.association)
      end
    end
  end
end
