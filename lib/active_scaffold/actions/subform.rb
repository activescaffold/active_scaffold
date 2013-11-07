module ActiveScaffold::Actions
  module Subform
    def edit_associated
      do_edit_associated
      render :action => 'edit_associated', :formats => [:js], :readonly => @column.association.options[:readonly]
    end

    protected

    def do_edit_associated
      @parent_record = params[:id].nil? ? new_model : find_if_allowed(params[:id], :update)
      generate_temporary_id(@parent_record, params[:generated_id]) if @parent_record.new_record? && params[:generated_id]
      @column = active_scaffold_config.columns[params[:child_association]]

      # NOTE: we don't check whether the user is allowed to update this record, because if not, we'll still let them associate the record. we'll just refuse to do more than associate, is all.
      @record = @column.association.klass.find(params[:associated_id]) if params[:associated_id]
      @record ||= build_associated(@column.association, @parent_record)
      @scope = params[:scope]
    end

  end
end
