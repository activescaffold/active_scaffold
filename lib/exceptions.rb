module ActiveScaffold
  class ColumnNotAllowed < SecurityError; end
  class ControllerNotFound < RuntimeError; end
  class DependencyFailure < RuntimeError; end
  class RecordNotAllowed < SecurityError; end
end
