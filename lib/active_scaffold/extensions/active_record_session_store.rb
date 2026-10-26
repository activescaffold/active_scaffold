# frozen_string_literal: true

module ActiveScaffold
  module Extensions
    module ActiveRecordSessionStore
      AFFECTED_VERSION = Gem::Version.new('2.3.0')

      # activerecord-session_store 2.3.0 keeps references to nested values in
      # the request session, so in-place changes can also alter the value used
      # for dirty comparison. Keep ActiveScaffold's request storage detached.
      module Core
        def active_scaffold_session_storage(id = nil)
          session_index = active_scaffold_session_storage_key(id)
          @active_scaffold_session_storage ||= {}

          storage = @active_scaffold_session_storage[session_index]
          return storage if storage && session[session_index].equal?(storage)

          storage = session[session_index]&.deep_dup || {}
          session[session_index] = storage
          @active_scaffold_session_storage[session_index] = storage
        end
      end

      def self.affected?(application = Rails.application)
        store_class = active_record_store
        version = session_store_version
        return false unless store_class && version

        configured_store = application.config.session_store
        uses_active_record_store =
          configured_store == store_class ||
          (configured_store.is_a?(Class) && configured_store < store_class)

        uses_active_record_store && Gem::Version.new(version) == AFFECTED_VERSION
      end

      def self.active_record_store
        ::ActionDispatch::Session::ActiveRecordStore if defined?(::ActionDispatch::Session::ActiveRecordStore)
      end
      private_class_method :active_record_store

      def self.session_store_version
        ::ActiveRecord::SessionStore::VERSION if defined?(::ActiveRecord::SessionStore::VERSION)
      end
      private_class_method :session_store_version
    end
  end
end
