module ActionController #:nodoc:
  class Base
    def deny_access
      head :unauthorized
    end
  end
end
