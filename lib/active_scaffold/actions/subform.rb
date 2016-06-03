module ActiveScaffold::Actions
  module Subform
    def edit_associated
      do_edit_associated
      render :action => 'edit_associated', :formats => [:js], :readonly => @column.association.options[:readonly]
    end

    protected

    def do_edit_associated
      @parent_record = params[:id].nil? ? new_model : find_if_allowed(params[:id], :update)
      if @parent_record.new_record?
        apply_constraints_to_record @parent_record
        create_association_with_parent @parent_record if nested?
      end

      generate_temporary_id(@parent_record, params[:generated_id]) if @parent_record.new_record? && params[:generated_id]
      @column = active_scaffold_config.columns[params[:child_association]]

      # NOTE: we don't check whether the user is allowed to update this record, because if not, we'll still let them associate the record. we'll just refuse to do more than associate, is all.
      if params[:associated_id]
        @record = @column.association.klass.find(params[:associated_id])
        if nested? # Generate a form that will update on save
          # Store the associated_record in @parent_record, but avoid save - that is handled on form submit.
          @parent_record.send("#{params[:child_association]}=", @record)
        else # Edit the association directly.
          if (association = active_scaffold_config.columns[params[:child_association]].association.reverse)
            if @record.class.reflect_on_association(association).collection?
              @record.send(association) << @parent_record
            else
              @record.send("#{association}=", @parent_record)
            end
          end
        end
      else
        @record = build_associated(@column.association, @parent_record)
      end
      @scope = params[:scope]
    end
  end
end
