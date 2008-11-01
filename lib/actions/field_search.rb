module ActiveScaffold::Actions
  module FieldSearch
    def self.included(base)
      base.before_filter :field_search_authorized?, :only => :show_search
      base.before_filter :do_search
    end

    # FieldSearch uses params[:search] and not @record because search conditions do not always pass the Model's validations.
    # This facilitates for example, textual searches against associations via .search_sql
    def show_search
      params[:search] ||= {}
      respond_to do |type|
        type.html { render(:action => "field_search") }
        type.js { render(:partial => "field_search", :layout => false) }
      end
    end

    protected

    def do_search
      @record = active_scaffold_config.model.new
      unless params[:search].nil?
        # set values to search in @record, because helper methods in view use @record to fill the fields
        associations, values = params[:search].partition {|key, value| value.is_a?(Hash)}
        @record.attributes = Hash[*values.reject{|key, value| value.blank?}.flatten]
        complex_conditions = {}
        associations.each do |key, value|
          column = active_scaffold_config.columns[key]
          if column.association
            next if value[:id].blank? # it hasn't a value to search
            associated = column.association.klass.find(value[:id])
            @record.send("#{key}=", column.singular_association? ? associated : [*associated])
          else # if value is a hash and column doesn't have association, is a search_ui with a complex condition
            complex_conditions[key] = value
          end
        end

        like_pattern = active_scaffold_config.field_search.full_text_search? ? '%?%' : '?%'
        conditions = self.active_scaffold_conditions
        columns = active_scaffold_config.field_search.columns
        columns.each do |column|
          value = complex_conditions.include?(column.name.to_s) ? complex_conditions[column.name.to_s] : @record.send(column.name)
          conditions = merge_conditions(conditions, ActiveScaffold::Finder.condition_for_column(column, value, like_pattern))
        end
        self.active_scaffold_conditions = conditions

        includes_for_search_columns = columns.collect{ |column| column.includes}.flatten.uniq.compact
        self.active_scaffold_joins.concat includes_for_search_columns

        active_scaffold_config.list.user.page = nil
      end
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def field_search_authorized?
      authorized_for?(:action => :read)
    end
  end
end
