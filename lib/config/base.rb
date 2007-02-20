module ActiveScaffold::Config
  class Base
    include ActiveScaffold::Configurable
    extend ActiveScaffold::Configurable

    # the user property gets set to the instantiation of the local UserSettings class during the automatic instantiation of this class.
    attr_accessor :user

    class UserSettings
      def initialize(conf, session, params)
        action_name = self.class.to_s.split('::')[-2].downcase.underscore.to_sym
        storage_id = 'm:' + params[:controller]
        session[storage_id] ||= {}
        session[storage_id][action_name] ||= {}

        # the session hash relevant to this action
        @session = session[storage_id][action_name]
        # all the request params
        @params = params
        # the configuration object for this action
        @conf = conf
      end
    end
  end
end