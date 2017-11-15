module ActiveScaffold
  module LookupContext
    attr_accessor :last_template

    def find_template(name, prefixes = [], partial = false, keys = [], options = {})
      self.last_template = super(name, prefixes, partial, keys, options)
    end
  end
end

# wrap the action rendering for ActiveScaffold views
module ActiveScaffold #:nodoc:
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
    # options[:xhr] force to load embedded scaffold with AJAX even when render_component gem is installed.
    #
    def render(*args, &block)
      if args.first.is_a?(Hash) && args.first[:active_scaffold]
        render_embedded args.first
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
        result = super options
        lookup_context.view_paths = @_view_paths if @_view_paths
        lookup_context.last_template = @_last_template if @_last_template
        result
      else
        @_view_paths ||= lookup_context.view_paths.clone
        last_template = lookup_context.last_template
        current_view = if args[0].is_a?(Hash)
                         {:locals => args[0][:locals], :object => args[0][:object]}
                       else # call is render 'partial', locals_hash
                         {:locals => args[1]}
                       end
        view_stack << current_view if current_view
        lookup_context.view_paths = @_view_paths # reset view_paths in case a view render :super, and then render :partial
        result = super
        view_stack.pop if current_view.present?
        lookup_context.last_template = last_template
        result
      end
    end

    def view_stack
      @_view_stack ||= []
    end

    private

    def render_embedded(options)
      require 'digest/md5'

      remote_controller = options[:active_scaffold]
      # It is important that the EID hash remains short as to not contribute
      # to a large session size and thus a possible cookie overflow exception
      # when using rails CookieStore or EncryptedCookieStore. For example,
      # when rendering many embedded scaffolds with constraints or conditions
      # on a single page.
      eid = Digest::MD5.hexdigest(params[:controller] + options.to_s)
      eid_info = {loading: true}
      eid_info[:constraints] = options[:constraints] if options[:constraints]
      eid_info[:conditions] = options[:conditions] if options[:conditions]
      eid_info[:label] = options[:label] if options[:label]
      options[:params] ||= {}
      options[:params].merge! :eid => eid, :embedded => eid_info

      id = "as_#{eid}-embedded"
      url_options = {controller: remote_controller.to_s, action: 'index', id: nil}.merge(options[:params])

      if controller.respond_to?(:render_component_into_view, true) && !options[:xhr]
        controller.send(:render_component_into_view, url_options)
      else
        url = url_for(url_options)
        content_tag(:div, :id => id, :class => 'active-scaffold-component', :data => {:refresh => url}) do
          # parse the ActiveRecord model name from the controller path, which
          # might be a namespaced controller (e.g., 'admin/admins')
          model = remote_controller.to_s.sub(/.*\//, '').singularize
          content_tag(:div, :class => 'active-scaffold-header') do
            content_tag :h2, link_to(options[:label] || active_scaffold_config_for(model).list.label, url, :remote => true, :class => 'load-embedded')
          end
        end
      end
    end
  end
end

module ActionView
  LookupContext.class_eval do
    prepend ActiveScaffold::LookupContext
  end

  module Helpers
    Base.class_eval do
      include ActiveScaffold::RenderingHelper
    end
  end
end
