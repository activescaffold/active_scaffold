module ActiveScaffold::Actions
  module Mark

    def self.included(base)
      base.before_filter :mark_authorized?, :only => :mark
      #base.prepend_before_filter :assign_marked_records_to_model
      base.helper_method :marked_records
    end

    def mark_all
      if mark_all? || mark_all_scope_forced?
        do_mark_all
      else
        do_unmark
      end
      do_list
      respond_to_action(:mark_all)
    end
    protected

    def mark_all_respond_to_html
      list_respond_to_html
    end

    def mark_all_respond_to_js
      render :action => 'on_mark_all', :locals => {:mark_all => mark_all?}
    end
 
    # We need to give the ActiveRecord classes a handle to currently marked records. We don't want to just pass the object,
    # because the object may change. So we give ActiveRecord a proc that ties to the
    # marked_records_method on this ApplicationController.
    def assign_marked_records_to_model
      active_scaffold_config.model.marked_records = marked_records
    end

    def mark?
      params[:value] == 'true'
    end
    
    def mark_all?
      @mark_all ||= [true, 'true', 1, '1', 'T', 't'].include?(params[:value].class == String ? params[:value].downcase : params[:value])
    end

    def mark_all_scope_forced?
      !params[:mark_target].nil? && params[:mark_target]=='scope'
    end
    
    def do_mark_all
      if active_scaffold_config.mark.mark_all_mode == :page && !mark_all_scope_forced? then
        each_record_in_page {|record| marked_records << record.id}
      else
        each_record_in_scope {|record| marked_records << record.id}
      end
    end

    def do_demark_all
      if active_scaffold_config.mark.mark_all_mode == :page then
        each_record_in_page {|record| marked_records.delete(record.id)}
      else
        each_record_in_scope {|record| marked_records.delete(record.id)}
      end
    end
    
    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def mark_authorized?
      authorized_for?(:crud_type => :read)
    end

    def mark_all_formats
      (default_formats + active_scaffold_config.formats).uniq
    end
  end
end
