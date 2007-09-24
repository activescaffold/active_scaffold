# The view_paths functionality in Edge Rails (Rails 2.0) doesn't support
# the idea of a fallback generic template file, such as what make ActiveScaffold
# work. This patch adds generic_view_paths, which are folders containing templates
# that may apply to all controllers.

# if render_action exists, we can use our existing hooks.
unless ActionController::Base.method_defined? :render_action

class ActionController::Base
  class_inheritable_accessor :generic_view_paths
  self.generic_view_paths = []
end

class ActionView::Base
  private
  def find_full_template_path_with_generic_paths(template_path, extension)
    path = find_full_template_path_without_generic_paths(template_path, extension)
    if path and not path.empty?
      path
    else
      template_file = File.basename("#{template_path}.#{extension}")
      path = find_generic_base_path_for(template_file)
      path ? "#{path}/#{template_file}" : ""
    end
  end
  alias_method_chain :find_full_template_path, :generic_paths

  # Returns the view path that contains the given relative template path.
  def find_generic_base_path_for(template_file_name)
    controller.generic_view_paths.find { |p| File.file?(File.join(p, template_file_name)) }
  end
end

end