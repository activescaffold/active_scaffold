# wrap find_template to search in ActiveScaffold paths when template is missing
module ActionView #:nodoc:
  class PathSet
    attr_accessor :active_scaffold_paths

    def find_template_with_active_scaffold(original_template_path, format = nil)
      begin
        find_template_without_active_scaffold(original_template_path, format)
      rescue MissingTemplate
        if active_scaffold_paths && original_template_path.include?('/')
          active_scaffold_paths.find_template_without_active_scaffold(original_template_path.split('/').last, format)
        else
          raise
        end
      end
    end
    alias_method_chain :find_template, :active_scaffold
  end
end

module ActionController #:nodoc:
  class Base
    def initialize_template_class_with_active_scaffold(response)
      initialize_template_class_without_active_scaffold(response)
      response.template.view_paths.active_scaffold_paths = self.class.active_scaffold_paths
    end
    alias_method_chain :initialize_template_class, :active_scaffold
  end
end
