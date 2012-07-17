module ActionView
  class LookupContext
    module ViewPaths
      def find_all_templates(name, partial = false, locals = {})
        prefixes.collect do |prefix|
          view_paths.collect do |resolver|
            temp_args = *args_for_lookup(name, [prefix], partial, locals, {})
            temp_args[1] = temp_args[1][0]
            resolver.find_all(*temp_args)
          end
        end.flatten!
      end
    end
  end
end

# wrap the action rendering for ActiveScaffold views
module ActionView::Helpers #:nodoc:
  module RenderingHelper
    #
    # Adds two rendering options.
    #
    # ==render :super
    #
    # This syntax skips all template overrides and goes directly to the provided ActiveScaffold templates.
    # Useful if you want to wrap an existing template. Just call super!
    #
    # ==render :active_scaffold => #{controller.to_s}, options = {}+
    #
    # Lets you embed an ActiveScaffold by referencing the controller where it's configured.
    #
    # You may specify options[:constraints] for the embedded scaffold. These constraints have three effects:
    #   * the scaffold's only displays records matching the constraint
    #   * all new records created will be assigned the constrained values
    #   * constrained columns will be hidden (they're pretty boring at this point)
    #
    # You may also specify options[:conditions] for the embedded scaffold. These only do 1/3 of what
    # constraints do (they only limit search results). Any format accepted by ActiveRecord::Base.find is valid.
    #
    # Defining options[:label] lets you completely customize the list title for the embedded scaffold.
    #
    def render_with_active_scaffold(*args, &block)
      if args.first == :super
        last_view = view_stack.last || {:view => instance_variable_get(:@virtual_path).split('/').last}
        options = args[1] || {}
        options[:locals] ||= {}
        options[:locals].reverse_merge!(last_view[:locals] || {})
        if last_view[:templates].nil?
          last_view[:templates] = lookup_context.find_all_templates(last_view[:view], last_view[:partial], options[:locals].keys)
          last_view[:templates].shift
        end
        options[:template] = last_view[:templates].shift
        view_stack << last_view
        result = render_without_active_scaffold options
        view_stack.pop
        result
      elsif args.first.is_a? Hash and args.first[:active_scaffold]
        require 'digest/md5'
        options = args.first

        remote_controller = options[:active_scaffold]
        constraints = options[:constraints]
        conditions = options[:conditions]
        eid = Digest::MD5.hexdigest(params[:controller] + remote_controller.to_s + constraints.to_s + conditions.to_s)
        session["as:#{eid}"] = {:constraints => constraints, :conditions => conditions, :list => {:label => args.first[:label]}}
        options[:params] ||= {}
        options[:params].merge! :eid => eid, :embedded => true

        id = "as_#{eid}-embedded"
        url_options = {:controller => remote_controller.to_s, :action => 'index'}.merge(options[:params])

        if controller.respond_to?(:render_component_into_view)
          controller.send(:render_component_into_view, url_options)
        else
          content_tag(:div, :id => id, :class => 'active-scaffold-component') do
            url = url_for(url_options)
            # parse the ActiveRecord model name from the controller path, which
            # might be a namespaced controller (e.g., 'admin/admins')
            model = remote_controller.to_s.sub(/.*\//, '').singularize
            content_tag(:div, :class => 'active-scaffold-header') do
              content_tag :h2, link_to(args.first[:label] || active_scaffold_config_for(model).list.label, url, :remote => true)
            end <<
            if ActiveScaffold.js_framework == :prototype
              javascript_tag("new Ajax.Updater('#{id}', '#{url}', {method: 'get', evalScripts: true});")
            elsif ActiveScaffold.js_framework == :jquery
              javascript_tag("jQuery('##{id}').load('#{url}');")
            end
          end
        end

      else
        options = args.first
        if options.is_a?(Hash)
          current_view = {:view => options[:partial], :partial => true} if options[:partial]
          current_view = {:view => options[:template], :partial => false} if current_view.nil? && options[:template]
          current_view[:locals] = options[:locals] if !current_view.nil? && options[:locals]
          view_stack << current_view if current_view.present?
        end
        result = render_without_active_scaffold(*args, &block)
        view_stack.pop if current_view.present?
        result
      end
    end
    alias_method_chain :render, :active_scaffold
    
    def view_stack
      @_view_stack ||= []
    end

  end
end
