# wrap the action rendering for ActiveScaffold controllers
module ActionController #:nodoc:
  class Base
    def render_with_active_scaffold(*args, &block)
      if self.class.uses_active_scaffold? and params[:adapter] and @rendering_adapter.nil?
        @rendering_adapter = true # recursion control
        # if we need an adapter, then we render the actual stuff to a string and insert it into the adapter template
        render :file => rewrite_template_path_for_active_scaffold(params[:adapter]),
               :locals => {:payload => render_to_string(args.first, &block)},
               :use_full_path => true
        @rendering_adapter = nil # recursion control
      else
        render_without_active_scaffold(*args, &block)
      end
    end
    alias_method_chain :render, :active_scaffold

    # Rails 2.x implementation is post-initialization on :active_scaffold method

    private

    def rewrite_template_path_for_active_scaffold(path)
      # test for the actual file
      return path if template_exists? default_template_name(path)
      # check the ActiveScaffold-specific directories
      active_scaffold_config.template_search_path.each do |template_path|
        full_path = File.join(template_path, path)
        return full_path if template_exists? full_path
      end
      return path
    end
  end
end
