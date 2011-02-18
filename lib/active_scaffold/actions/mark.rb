module ActiveScaffold::Actions
  module Mark

    def self.included(base)
      base.before_filter :mark_authorized?, :only => [:mark_all]
      base.prepend_before_filter :assign_marked_records_to_model
      base.helper_method :marked_records
    end

    def mark_all
      if mark_all?
        do_mark_all
      else
        do_demark_all
      end
      respond_to_action(:mark_all)
    end
 protected

    def mark_all_respond_to_html
      do_list
      list_respond_to_html
    end

    def mark_all_respond_to_js
      do_list
      render :action => 'on_mark_all', :locals => {:mark_all => mark_all?}
    end
 
    # We need to give the ActiveRecord classes a handle to currently marked records. We don't want to just pass the object,
    # because the object may change. So we give ActiveRecord a proc that ties to the
    # marked_records_method on this ApplicationController.
    def assign_marked_records_to_model
      active_scaffold_config.model.marked_records = marked_records
    end
    
    def marked_records
      active_scaffold_session_storage[:marked_records] ||= Set.new
    end
    
    def mark_all?
      @mark_all ||= [true, 'true', 1, '1', 'T', 't'].include?(params[:value].class == String ? params[:value].downcase : params[:value])
    end

    def do_mark_all
      each_record_in_scope {|record| marked_records << record.id}
    end

    def do_demark_all
      each_record_in_scope {|record| marked_records.delete(record.id)}
    end
    
    # The default security delegates to ActiveRecordPermissions.
    # You may override the method to customize.
    def mark_authorized?
      authorized_for?(:action => :read)
    end

    def mark_all_formats
      (default_formats + active_scaffold_config.formats).uniq
    end
  end
end