module ActionView
  class ActiveScaffoldResolver < FileSystemResolver
    def build_path(name, prefix, partial, details)
      super(name, '', partial, details)
    end
  end
end
