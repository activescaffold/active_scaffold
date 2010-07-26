module ActiveScaffold::Actions
  module Mark

    def self.included(base)
      base.before_filter :mark_authorized?, :only => :mark
      #base.prepend_before_filter :assign_marked_records_to_model
      base.helper_method :marked_records
    end

    def mark
      if mark?
        do_mark
      else
        do_unmark
      end
      mark_respond_to_js
    end

    protected
    # We need to give the ActiveRecord classes a handle to currently marked records. We don't want to just pass the object,
    # because the object may change. So we give ActiveRecord a proc that ties to the
    # marked_records_method on this ApplicationController.
    def assign_marked_records_to_model
      active_scaffold_config.model.marked_records_proc = proc {send(:marked_records)}
    end

    def mark?
      params[:value] == 'true'
    end
    
    def do_mark
      if params[:id]
        marked_records << params[:id]
      else
        each_record_in_scope {|record| marked_records << record.id.to_s}
      end
    end

    def do_unmark
      if params[:id]
        marked_records.delete params[:id]
      else
        each_record_in_scope {|record| marked_records.delete(record.id.to_s)}
      end
    end
    
    def each_record_in_scope
      do_search if respond_to? :do_search
      set_includes_for_list_columns
      find_options = finder_options
      find_options[:include] = nil if find_options[:conditions].nil?
      beginning_of_chain.all(find_options).each {|record| yield record}
    end

    def mark_respond_to_js
      if params[:id]
        do_search if respond_to? :do_search
        set_includes_for_list_columns
        count = beginning_of_chain.count(count_options(finder_options, active_scaffold_config.list.user.count_includes))
        @mark = marked_records.length >= count
      else
        @mark = mark?
      end
    end

    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def mark_authorized?
      authorized_for?(:crud_type => :read)
    end
  end
end
