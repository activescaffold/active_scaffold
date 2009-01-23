class ActiveScaffoldPath < ActionView::Template::Path
  def [](path)
    path = path.split('/').last
    templates_in_path do |template|
      if template.accessible_paths.include?(path)
        return template
      end
    end
    nil
  end
end
