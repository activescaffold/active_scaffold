module ActionView
  class LookupContext
    attr_accessor :last_template

    def find_template_with_last_template(name, prefixes = [], partial = false, keys = [], options = {})
      self.last_template = find_template_without_last_template(name, prefixes, partial, keys, options)
    end
    alias_method_chain :find_template, :last_template
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
      if args.first.is_a?(Hash) && args.first[:active_scaffold]
        require 'digest/md5'
        options = args.first

        remote_controller = options[:active_scaffold]
        constraints = options[:constraints]
        conditions = options[:conditions]
        eid = Digest::MD5.hexdigest(params[:controller] + remote_controller.to_s + constraints.to_s + conditions.to_s)
        eid_info = session["as:#{eid}"] ||= {}
        if constraints
          eid_info['constraints'] = constraints
        else
          eid_info.delete 'constraints'
        end
        if conditions
          eid_info['conditions'] = conditions
        else
          eid_info.delete 'conditions'
        end
        if options[:label]
          eid_info['list'] = {'label' => options[:label]}
        else
          eid_info.delete 'list'
        end
        session.delete "as:#{eid}" if eid_info.empty?
        options[:params] ||= {}
        options[:params].merge! :eid => eid, :embedded => true

        id = "as_#{eid}-embedded"
        url_options = {:controller => remote_controller.to_s, :action => 'index'}.merge(options[:params])

        if controller.respond_to?(:render_component_into_view, true)
          controller.send(:render_component_into_view, url_options)
        else
          url = url_for(url_options)
          content_tag(:div, :id => id, :class => 'active-scaffold-component', :data => {:refresh => url}) do
            # parse the ActiveRecord model name from the controller path, which
            # might be a namespaced controller (e.g., 'admin/admins')
            model = remote_controller.to_s.sub(/.*\//, '').singularize
            content_tag(:div, :class => 'active-scaffold-header') do
              content_tag :h2, link_to(args.first[:label] || active_scaffold_config_for(model).list.label, url, :remote => true, :class => 'load-embedded')
            end
          end
        end

      elsif args.first == :super
        @_view_paths ||= lookup_context.view_paths.clone
        @_last_template ||= lookup_context.last_template
        parts = @virtual_path.split('/')
        template = parts.pop
        prefix = parts.join('/')

        options = args[1] || {}
        options[:locals] ||= {}
        if view_stack.last
          options[:locals] = view_stack.last[:locals].merge!(options[:locals]) if view_stack.last[:locals]
          options[:object] ||= view_stack.last[:object] if view_stack.last[:object]
        end
        options[:template] = template
        # if prefix is active_scaffold_overrides we must try to render with this prefix in following paths
        if prefix != 'active_scaffold_overrides'
          options[:prefixes] = lookup_context.prefixes.drop((lookup_context.prefixes.find_index(prefix) || -1) + 1)
        else
          options[:prefixes] = ['active_scaffold_overrides']
          last_view_path = File.expand_path(File.dirname(File.dirname(lookup_context.last_template.inspect)), Rails.root)
          lookup_context.view_paths = view_paths.drop(view_paths.find_index { |path| path.to_s == last_view_path } + 1)
        end
        result = render_without_active_scaffold options
        lookup_context.view_paths = @_view_paths if @_view_paths
        lookup_context.last_template = @_last_template if @_last_template
        result
      else
        @_view_paths ||= lookup_context.view_paths.clone
        last_template = lookup_context.last_template
        if args[0].is_a?(Hash)
          current_view = {:locals => args[0][:locals], :object => args[0][:object]}
        else # call is render 'partial', locals_hash
          current_view = {:locals => args[1]}
        end
        view_stack << current_view if current_view
        lookup_context.view_paths = @_view_paths # reset view_paths in case a view render :super, and then render :partial
        result = render_without_active_scaffold(*args, &block)
        view_stack.pop if current_view.present?
        lookup_context.last_template = last_template
        result
      end
    end
    alias_method_chain :render, :active_scaffold

    def view_stack
      @_view_stack ||= []
    end
  end
end
