# frozen_string_literal: true

module ActiveScaffold
  class Registry
    thread_mattr_accessor :current_user_proc, :current_ability_proc, :marked_records

    def self.user_settings
      RequestStore.store[:attr_Registry_user_settings] ||= {}
    end

    def self.constraint_columns
      RequestStore.store[:attr_Registry_constraint_columns] ||= Hash.new { |h, k| h[k] = [] }
    end

    def self.unauthorized_columns
      RequestStore.store[:attr_Registry_unauthorized_columns] ||= Hash.new { |h, k| h[k] = [] }
    end

    def self.column_links
      RequestStore.store[:column_links] ||= {}
    end

    def self.cache(kind, key = nil, &)
      unless key
        key = kind
        kind = :cache
      end
      RequestStore.store[:attr_Registry_cache] ||= {}
      cache = RequestStore.store[:attr_Registry_cache][kind] ||= {}
      return cache[key] if cache.include? key

      cache[key] ||= yield
    end
  end
end
