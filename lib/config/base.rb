module ActiveScaffold::Config
  class Base
    include ActiveScaffold::Configurable
    extend ActiveScaffold::Configurable

    # the user property gets set to the instantiation of the local UserSettings class during the automatic instantiation of this class.
    attr_accessor :user

    class UserSettings
      def initialize(conf, storage, params)
        # the session hash relevant to this action
        @session = storage
        # all the request params
        @params = params
        # the configuration object for this action
        @conf = conf
      end
    end
  end
end