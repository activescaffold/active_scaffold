# wrap the action rendering for ActiveScaffold views
module ActionView #:nodoc:
  class Base
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
    # Defining options[:label] lets you completely customize the list title for the embedded scaffold.
    #
    def render_with_active_scaffold(*args)

      if args.first == :super
        template_path = caller.first.split(':').first
        template = File.basename(template_path)

        ActiveScaffold::Config::Core.template_search_path.each do |active_scaffold_template_path|
          active_scaffold_template = File.join(active_scaffold_template_path, template)
          return render :file => active_scaffold_template if file_exists? active_scaffold_template
        end
      elsif args.first[:active_scaffold]
        require 'digest/md5'
        options = args.first

        remote_controller = options[:active_scaffold]
        constraints = options[:constraints]
        eid = Digest::MD5.hexdigest(params[:controller] + remote_controller.to_s + constraints.to_s)
        session["as:#{eid}"] = {:constraints => constraints, :list => {:label => args.first[:label]}}
        options[:params] ||= {}
        options[:params].merge! :eid => eid

        render_component :controller => remote_controller.to_s, :action => 'table', :params => options[:params]
      else
        render_without_active_scaffold *args
      end
    end
    alias_method :render_without_active_scaffold, :render
    alias_method :render, :render_with_active_scaffold

    def render_partial_with_active_scaffold(partial_path, local_assigns = nil, deprecated_local_assigns = nil) #:nodoc:
      if self.controller.class.respond_to?(:uses_active_scaffold?) and self.controller.class.uses_active_scaffold?
        partial_path = rewrite_partial_path_for_active_scaffold(partial_path)
      end
      render_partial_without_active_scaffold(partial_path, local_assigns, deprecated_local_assigns)
    end
    alias_method :render_partial_without_active_scaffold, :render_partial
    alias_method :render_partial, :render_partial_with_active_scaffold

    private

    def rewrite_partial_path_for_active_scaffold(partial_path)
      path, partial_name = partial_pieces(partial_path)

      # test for the actual file
      return partial_path if file_exists? File.join(path, "_#{partial_name}")

      # check the ActiveScaffold-specific directories
      ActiveScaffold::Config::Core.template_search_path.each do |template_path|
        return File.join(template_path, partial_name) if file_exists? File.join(template_path, "_#{partial_name}")
      end
      return partial_path
    end
  end
end

module ActionView
  module Helpers
    class InstanceTag
      # patch an issue with integer size parameters
      def to_text_area_tag(options = {})
        options = DEFAULT_TEXT_AREA_OPTIONS.merge(options.stringify_keys)
        add_default_name_and_id(options)

        if size = options.delete("size")
          options["cols"], options["rows"] = size.split("x") if size.class == String
        end

        if method(:value_before_type_cast).arity > 0
          content_tag("textarea", html_escape(options.delete('value') || value_before_type_cast(object)), options)
        else
          content_tag("textarea", html_escape(options.delete('value') || value_before_type_cast), options)
        end
      end

      private

      # patch in support for options[:name]
      def options_with_prefix_with_name(position, options)
        if options[:name]
          options.merge(:prefix => options[:name].dup.insert(-2, "(#{position}i)"))
        else
          options_with_prefix_without_name(position, options)
        end
      end
      alias_method_chain :options_with_prefix, :name
    end
  end
end