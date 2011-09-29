module ActiveScaffold::Actions
  module Subform
    def edit_associated
      do_edit_associated
      render :action => 'edit_associated.js'
    end

    protected

    def do_edit_associated
      @parent_record = params[:id].nil? ? new_model : find_if_allowed(params[:id], :update)
      @column = active_scaffold_config.columns[params[:association]]

      # NOTE: we don't check whether the user is allowed to update this record, because if not, we'll still let them associate the record. we'll just refuse to do more than associate, is all.
      @record = @column.association.klass.find(params[:associated_id]) if params[:associated_id]
      @record ||= @column.singular_association? ? @parent_record.send("build_#{@column.name}".to_sym) : @parent_record.send(@column.name).build
      reflection = @parent_record.class.reflect_on_association(@column.name)
      if reflection && reflection.reverse && @parent_record.new_record?
        reverse_macro = @record.class.reflect_on_association(reflection.reverse).macro
        if [:has_one, :belongs_to].include?(reverse_macro) # singular
          @record.send(:"#{reflection.reverse}=", @parent_record)
        # TODO: Might want to extend with this branch in the future
        # else # plural
        #   @record.send(:"#{reflection.reverse}") << @parent_record
        end
      end

      @scope = "[#{@column.name}]"
      @scope += (@record.new_record?) ? "[#{(Time.now.to_f*1000).to_i.to_s}]" : "[#{@record.id}]" if @column.plural_association?
    end

  end
end
