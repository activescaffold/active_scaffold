module ActionController #:nodoc:
  class Base
    # adding to ActionController::Base so it can overrided in ApplicationController
    def deny_access
      head :unauthorized
    end
  end
end
