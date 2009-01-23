class ActionController::Base
  class_inheritable_accessor :generic_view_paths
  self.generic_view_paths = []

  # Returns the view path that contains the given relative template path.
  def find_generic_base_path_for(template_path, extension)
    self.generic_view_paths.each do |generic_path|
      template_file_name = File.basename("#{template_path}.#{extension}")
      generic_file_path = File.join(generic_path, template_file_name)
      return generic_file_path if File.file?(generic_file_path)
    end
    nil
  end
end

class ActionView::Base
  def template_exists?(template)
    begin
      return _pick_template(template)
    rescue ActionView::MissingTemplate
      return nil
    end
  end

  private
  def _pick_template_with_generic(template_path)
    return template_path if template_path.respond_to?(:render)

    path = template_path.sub(/^\//, '')
    if m = path.match(/(.*)\.(\w+)$/)
      template_file_name, template_file_extension = m[1], m[2]
    else
      template_file_name = path
    end
    if m = template_file_name.match(/\/(\w+)$/)
      generic_template = m[1]
    end
    
    # OPTIMIZE: Checks to lookup template in view path
    if template = self.view_paths["#{template_file_name}.#{template_format}"]
      template
    elsif template = self.view_paths[template_file_name]
      template
    elsif template = self.view_paths[generic_template]
      template
    elsif (first_render = @_render_stack.first) && first_render.respond_to?(:format_and_extension) &&
        (template = self.view_paths["#{template_file_name}.#{first_render.format_and_extension}"])
      template
    elsif template_format == :js && template = self.view_paths["#{template_file_name}.html"]
      @template_format = :html
      template
    else
      template = ActionView::Template.new(template_path, view_paths)

      if self.class.warn_cache_misses && logger
        logger.debug "[PERFORMANCE] Rendering a template that was " +
          "not found in view path. Templates outside the view path are " +
          "not cached and result in expensive disk operations. Move this " +
          "file into #{view_paths.join(':')} or add the folder to your " +
          "view path list"
      end

      template
    end
  end
  alias_method_chain :_pick_template, :generic

end
