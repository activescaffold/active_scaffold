module ActiveScaffold::Actions
  module FieldSearch
    include ActiveScaffold::Actions::CommonSearch
    def self.included(base)
      base.before_filter :search_authorized_filter, :only => :show_search
      base.before_filter :store_search_params_into_session, :only => [:index]
      base.before_filter :do_search, :only => [:index]
      base.helper_method :field_search_params
    end

    # FieldSearch uses params[:search] and not @record because search conditions do not always pass the Model's validations.
    # This facilitates for example, textual searches against associations via .search_sql
    def show_search
      @record = new_model
      respond_to_action(:field_search)
    end

    protected
    
    def store_search_params_into_session
      set_field_search_default_params(active_scaffold_config.field_search.default_params) unless active_scaffold_config.field_search.default_params.nil?
      super
      active_scaffold_session_storage[:search] = nil if search_params.is_a?(String)
    end
    
    def set_field_search_default_params(default_params)
      if (params[:search].nil? && search_params.nil?) || (params[:search].is_a?(String) && params[:search].blank?)
        params[:search] = default_params.is_a?(Proc) ? self.instance_eval(&default_params) : default_params
      end
    end
    
    def field_search_params
      search_params || {}
    end

    def field_search_respond_to_html
      render(:action => "field_search")
    end
    
    def field_search_respond_to_js
      render(:partial => "field_search")
    end

    def do_search
      unless search_params.nil?
        text_search = active_scaffold_config.field_search.text_search
        search_conditions = []
        human_condition_columns = [] if active_scaffold_config.field_search.human_conditions
        columns = active_scaffold_config.field_search.columns
        search_params.each do |key, value|
          next unless columns.include? key
          search_condition = self.class.condition_for_column(active_scaffold_config.columns[key], value, text_search)
          unless search_condition.blank?
            search_conditions << search_condition
            human_condition_columns << active_scaffold_config.columns[key] unless human_condition_columns.nil?
          end
        end
        self.active_scaffold_conditions = merge_conditions(self.active_scaffold_conditions, *search_conditions)
        if search_conditions.blank?
          @filtered = false
        else
          @filtered = human_condition_columns.nil? ? true : human_condition_columns
        end

        includes_for_search_columns = columns.collect{ |column| column.includes}.flatten.uniq.compact
        self.active_scaffold_includes.concat includes_for_search_columns

        active_scaffold_config.list.user.page = nil
      end
    end

    private
    
    def search_authorized_filter
      link = active_scaffold_config.field_search.link || active_scaffold_config.field_search.class.link
      raise ActiveScaffold::ActionNotAllowed unless self.send(link.security_method)
    end
    def field_search_formats
      (default_formats + active_scaffold_config.formats + active_scaffold_config.field_search.formats).uniq
    end
  end
end
