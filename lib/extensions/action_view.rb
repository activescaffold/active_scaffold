# wrap the action rendering for ActiveScaffold views
module ActionView #:nodoc:
  class Base
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
        remote_controller = args.first[:active_scaffold]
        constraints = args.first[:params]
        eid = Digest::MD5.hexdigest(params[:controller] + remote_controller.to_s + constraints.to_s)
        session["as:#{eid}"] = {:constraints => constraints}

        render_component :controller => remote_controller, :action => 'table', :params => {:eid => eid}
      else
        render_without_active_scaffold *args
      end
    end
    alias_method :render_without_active_scaffold, :render
    alias_method :render, :render_with_active_scaffold

    def render_partial_with_active_scaffold(partial_path, local_assigns = nil, deprecated_local_assigns = nil)
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

# patch an issue with integer size parameters
module ActionView
  module Helpers
    class InstanceTag
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
    end
  end
end