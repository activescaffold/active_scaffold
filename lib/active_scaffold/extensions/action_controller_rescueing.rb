module ActionController #:nodoc:
  class Base
    # adding to ActionController::Base so it can overrided in ApplicationController
    def deny_access
      head :forbidden # better for action or record not allowed, according to RFC 7231
    end
  end
end
