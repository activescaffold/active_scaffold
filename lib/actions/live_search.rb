module ActiveScaffold::Actions
  module LiveSearch
    include ActiveScaffold::Actions::Base
    def self.included(base)
      base.before_filter :do_search
    end

    def show_search
      respond_to do |type|
        type.html do
          if successful?
            render(:partial => "live_search", :layout => true)
          else
            return_to_main
          end
        end
        type.js { render(:partial => "live_search", :layout => false) }
      end
    end

    protected

    def do_search
      @query = params[:search].to_s.strip rescue ''

      unless @query.empty?
        columns = active_scaffold_config.live_search.columns
        self.active_scaffold_conditions = merge_conditions(self.active_scaffold_conditions, ActiveScaffold::Finder.create_conditions_for_columns(@query.split(' '), columns))

        includes_for_search_columns = columns.collect{ |column| column.includes}.flatten.uniq.compact
        self.active_scaffold_includes.concat includes_for_search_columns

        active_scaffold_config.list.user.page = nil
      end
    end
  end
end
