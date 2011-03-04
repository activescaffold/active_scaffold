module ActiveScaffold::Actions
  module Subform
    def edit_associated
      do_edit_associated
      render :action => 'edit_associated'
    end

    protected

    def do_edit_associated
      @parent_record = params[:id].nil? ? new_model : find_if_allowed(params[:id], :update)
      @column = active_scaffold_config.columns[params[:association]]

      # NOTE: we don't check whether the user is allowed to update this record, because if not, we'll still let them associate the record. we'll just refuse to do more than associate, is all.
      @record = @column.association.klass.find(params[:associated_id]) if params[:associated_id]
      @record ||= if @column.singular_association?
        @parent_record.send("build_#{@column.name}".to_sym)
      else
        @parent_record.send(@column.name).build
      end

      @scope = "[#{@column.name}]"
      @scope += (@record.new_record?) ? "[#{(Time.now.to_f*1000).to_i.to_s}]" : "[#{@record.id}]" if @column.plural_association?
    end

  end
end
