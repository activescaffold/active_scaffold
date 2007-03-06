module ActiveScaffold::Actions
  module Subform
    def edit_associated
      @parent_record = find_if_allowed(params[:id], 'update')
      @column = active_scaffold_config.columns[params[:association]]
      @record = find_if_allowed(params[:associated_id], 'update', @column.association.klass) if params[:associated_id]
      @record ||= @column.association.klass.new

      @scope = "[#{@column.name}]"
      @scope += (@record.new_record?) ? "[#{(Time.now.to_f*1000).to_i.to_s}]" : "[#{@record.id}]" if @column.plural_association?

      render :action => 'edit_associated.rjs', :layout => false
    end
  end
end