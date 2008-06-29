# The view_paths functionality in Edge Rails (Rails 2.0) doesn't support
# the idea of a fallback generic template file, such as what make ActiveScaffold
# work. This patch adds generic_view_paths, which are folders containing templates
# that may apply to all controllers.
#
# There is one major difference with generic_view_paths, though. They should
# *not* be used unless the action has been explicitly defined in the controller.
# This is in contrast to how Rails will normally bypass the controller if it sees
# a partial.

class ActionController::Base
  class_inheritable_accessor :generic_view_paths
  self.generic_view_paths = []
end

class ActionView::Base
  def initialize_with_generic_paths(*args)
    initialize_without_generic_paths(*args)
    @finder.controller = @controller
  end
  alias_method_chain :initialize, :generic_paths
end

class ActionView::TemplateFinder
  attr_accessor :controller

  def pick_template_with_generic_paths(template_path, extension)
    path = pick_template_without_generic_paths(template_path, extension)
    if path.blank? and search_generic_view_paths?
      template_file = File.basename("#{template_path}.#{extension}")
      path = find_generic_base_path_for(template_file)
      path = path ? "#{path}/#{template_file}" : nil
    end
    path
  end
  alias_method_chain :pick_template, :generic_paths
  alias_method :template_exists?, :pick_template # re-alias to the new pick_template
  
  def find_template_extension_from_handler_with_generic_paths(template_path, template_format = @template.template_format)
    extension = find_template_extension_from_handler_without_generic_paths(template_path, template_format)
    if extension.blank? and search_generic_view_paths?
      template_file = File.basename(template_path)
      controller.generic_view_paths.each do |path|
        self.class.template_handler_extensions.each do |handler_extension|
          return handler_extension if File.file?(File.join(path, "#{template_file}.#{handler_extension}"))
        end
      end
    end
    extension
  end
  alias_method_chain :find_template_extension_from_handler, :generic_paths

  # Returns the view path that contains the given relative template path.
  def find_generic_base_path_for(template_file_name)
    controller.generic_view_paths.find { |p| File.file?(File.join(p, template_file_name)) }
  end

  # We don't want to use generic_view_paths in ActionMailer, and we don't want
  # to use them unless the controller action was explicitly defined.
  def search_generic_view_paths?
    controller.respond_to?(:generic_view_paths) and controller.class.action_methods.include?(controller.action_name)
  end
end
