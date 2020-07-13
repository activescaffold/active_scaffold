module ActiveScaffold::Actions
  module Subform
    def edit_associated
      do_edit_associated
      respond_to do |format|
        format.js { render :action => 'edit_associated', :formats => [:js], :readonly => @column.association.readonly? }
      end
    end

    protected

    def do_edit_associated
      @parent_record = params[:id].nil? ? new_model : find_if_allowed(params[:id], :update)
      @scope = params[:scope]
      if @parent_record.new_record?
        # don't apply if scope, subform inside subform, because constraints won't apply to parent_record
        apply_constraints_to_record @parent_record unless @scope
        create_association_with_parent @parent_record if nested?
      end

      cache_generated_id(@parent_record, params[:generated_id]) if @parent_record.new_record?
      @column = active_scaffold_config.columns[params[:child_association]]

      @record = find_associated_record if params[:associated_id]
      @record ||= build_associated(@column.association, @parent_record)
    end

    def find_associated_record
      @column.association.klass.find(params[:associated_id]).tap do |record|
        save_record_to_association(record, @column.association.reverse_association, @parent_record, @column.association)
      end
    end
  end
end
