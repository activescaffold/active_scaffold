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
    alias_method :render_without_active_scaffold, :render
    alias_method :render, :render_with_active_scaffold

    def render_action_with_active_scaffold(action_name, status = nil, with_layout = true) #:nodoc:
      if self.class.uses_active_scaffold?
        path = rewrite_template_path_for_active_scaffold(action_name)
        return render(:template => path, :layout => with_layout, :status => status) if path != action_name
      end
      return render_action_without_active_scaffold(action_name, status, with_layout)
    end
    alias_method :render_action_without_active_scaffold, :render_action
    alias_method :render_action, :render_action_with_active_scaffold

    private

    def rewrite_template_path_for_active_scaffold(path)
      # test for the actual file
      return path if template_exists? default_template_name(path)

      # check the ActiveScaffold-specific directories
      ActiveScaffold::Config::Core.template_search_path.each do |template_path|
        full_path = File.join(template_path, path)
        return full_path if template_exists? full_path
      end
      return path
    end
  end
end

module ActionController #:nodoc:
  module Components
    module InstanceMethods
      # Extracts the action_name from the request parameters and performs that action.
      private
        # This is to fix a bug in Rails. 1.2.2 was calling klass.controller_name instead of klass.controller_path, which was in turn setting the params[:controller] => "contacts", instead of params[:controller] => "two/contact". Submitted ticket #7545
        # Namespaces only supported in MUI with Rails 1.2.2
        def component_response(options, reuse_response)
          klass    = component_class(options)
          request  = request_for_component(klass.controller_path, options)
          new_response = reuse_response ? response : response.dup

          klass.process_with_components(request, new_response, self)
        end
    end
  end
end