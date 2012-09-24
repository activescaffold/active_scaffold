module ActionView
  class LookupContext
    attr_accessor :last_template
    register_detail(:active_scaffold_view_paths) { nil }
    
    def find(name, prefixes = [], partial = false, keys = [], options = {})
      unless active_scaffold_view_paths && prefixes && prefixes.one? && prefixes.first.blank?
        args = args_for_lookup(name, prefixes, partial, keys, options)
        view_paths = @view_paths
        template = @view_paths.find_all(*args).first
      end
      if active_scaffold_view_paths && template.nil?
        view_paths = active_scaffold_view_paths.is_a?(ActionView::PathSet) ? active_scaffold_view_paths : ActionView::PathSet.new(active_scaffold_view_paths)
        args ||= args_for_lookup(name, '', partial, keys, options)
        template = view_paths.find(*args_for_lookup(name, '', partial, keys, options)) 
      end
      raise(MissingTemplate.new(view_paths, *args)) unless template
      self.last_template = template
    end
    alias :find_template :find
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
      if args.first.is_a? Hash and args.first[:active_scaffold]
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
              javascript_tag("jQuery('##{id}').load('#{url}', function() { $(this).trigger('as:element_updated'); });")
            end
          end
        end

      elsif args.first == :super
        prefix, template = @virtual_path.split('/')
        last_view = view_stack.last || {}
        options = args[1] || {}
        options[:locals] ||= {}
        options[:locals].reverse_merge!(last_view[:locals] || {})
        options[:template] = template || prefix
        # if template is nil we are rendering an active_scaffold (or active_scaffold's plugin) view
        if template
          options[:prefixes] = lookup_context.prefixes.drop((lookup_context.prefixes.find_index(prefix) || -1) + 1)
        else
          options[:prefixes] = ['']
          active_scaffold_view_paths = lookup_context.active_scaffold_view_paths
          last_view_path = File.expand_path(File.dirname(lookup_context.last_template.inspect), Rails.root)
          lookup_context.active_scaffold_view_paths = active_scaffold_view_paths.drop(active_scaffold_view_paths.find_index {|path| path.to_s == last_view_path} + 1)
        end
        result = render_without_active_scaffold options
        lookup_context.active_scaffold_view_paths = active_scaffold_view_paths unless template
        result
      else
        options = args.first
        current_view = {:locals => options[:locals]} if options.is_a?(Hash)
        view_stack << current_view if current_view.present?
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
