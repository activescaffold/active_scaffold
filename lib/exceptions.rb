module ActiveScaffold
  class ControllerNotFound < RuntimeError; end
  class DependencyFailure < RuntimeError; end
  class MalformedConstraint < RuntimeError; end
  class RecordNotAllowed < SecurityError; end
end
