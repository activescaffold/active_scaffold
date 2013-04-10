module ActiveScaffold::Actions
  module Mark

    def self.included(base)
      base.before_filter :mark_authorized?, :only => :mark
      base.before_filter :assign_marked_records_to_model
      base.helper_method :marked_records
    end

    def mark
      if mark? || mark_all_scope_forced?
        do_mark
      else
        do_demark
      end
      if marked_records.length > 0
        count = marked_records.length
        flash[:info] = as_(:records_marked, :count => count, :model => active_scaffold_config.label(:count => count))
      end
      respond_to_action(:mark)
    end
    protected

    def mark_respond_to_html
      do_list
      list_respond_to_html
    end

    def mark_respond_to_js
      if params[:id]
        do_search if respond_to? :do_search, true
        set_includes_for_columns if active_scaffold_config.actions.include? :list
        @page = find_page(:pagination => active_scaffold_config.mark.mark_all_mode != :page)
        render :action => 'on_mark'
      else
        render :action => 'on_mark', :locals => {:checked => mark?}
      end
    end
 
    # We need to give the ActiveRecord classes a handle to currently marked records. We don't want to just pass the object,
    # because the object may change. So we give ActiveRecord a proc that ties to the marked_records_method on this ApplicationController.
    def assign_marked_records_to_model
      active_scaffold_config.model.marked_records = marked_records
    end

    def mark?
      @mark ||= [true, 'true', 1, '1', 'T', 't'].include?(params[:value].class == String ? params[:value].downcase : params[:value])
    end

    def mark_all_scope_forced?
      params[:mark_target] == 'scope' unless params[:id]
    end

    def do_mark
      if params[:id]
        find_if_allowed(params[:id], :read).as_marked = true
      elsif active_scaffold_config.mark.mark_all_mode == :page && !mark_all_scope_forced?
        each_record_in_page { |record| record.as_marked = true }
      else
        each_record_in_scope { |record| record.as_marked = true }
      end
    end

    def do_demark
      if params[:id]
        find_if_allowed(params[:id], :read).as_marked = false
      elsif active_scaffold_config.mark.mark_all_mode == :page
        each_record_in_page { |record| record.as_marked = false }
      else
        each_record_in_scope { |record| record.as_marked = false }
      end
    end
    
    def do_destroy
      super
      @record.as_marked = false if successful?
    end
    
    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def mark_authorized?
      authorized_for?(:crud_type => :read)
    end

    def mark_formats
      (default_formats + active_scaffold_config.formats).uniq
    end
  end
end
