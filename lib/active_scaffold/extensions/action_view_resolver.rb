module ActionView
  class ActiveScaffoldResolver < FileSystemResolver
    # standard resolvers have a base path to views and append a controller subdirectory
    # activescaffolds view path do not have a subdir, so just remove the prefix
    def find_templates(name, prefix, partial, details)
      super(name,'',partial, details)
    end
  end
end
