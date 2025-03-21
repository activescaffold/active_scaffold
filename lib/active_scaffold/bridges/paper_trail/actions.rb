module ActiveScaffold::Actions
  module DeletedRecords
    def self.included(base)
      base.class_eval do
        config = active_scaffold_config
        if config.actions.include?(:nested) && config.deleted_records.nested_link_group
          config.configure do
            nested.add_link :versions, label: config.deleted_records.nested_link_label, action_group: config.deleted_records.nested_link_group
          end
        end
      end
    end

    def deleted
      query = PaperTrail::Version.destroys.where(item_type: active_scaffold_config.model.name)
      if nested? && nested.child_association&.belongs_to? && PaperTrail::Version.respond_to?(:where_object)
        foreign_key = nested.child_association.foreign_key
        parent_id = nested.parent_id
        parent_id = parent_id&.to_i if self.class.active_scaffold_config.columns[foreign_key]&.number?
        query = query.where_object(foreign_key => parent_id)
      end
      pager = Paginator.new(query.count, active_scaffold_config.list.per_page) do |offset, per_page|
        query.offset(offset).limit(per_page).map(&:reify)
      end
      @pagination_action = :deleted
      @page = pager.page(params[:page] || 1)
      @records = @page.items
      respond_to_action(:list)
    end
  end
end
