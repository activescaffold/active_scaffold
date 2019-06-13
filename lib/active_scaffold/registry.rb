module ActiveScaffold
  class Registry
    extend ActiveSupport::PerThreadRegistry
    attr_accessor :current_user_proc, :current_ability_proc, :marked_records

    def user_settings
      @user_settings ||= {}
    end

    def constraint_columns
      @constraint_columns ||= Hash.new { |h, k| h[k] = [] }
    end

    def unauthorized_columns
      @unauthorized_columns ||= Hash.new { |h, k| h[k] = [] }
    end

    def cache(kind, key = nil, &block)
      full_key = key ? "#{kind}/#{key}" : kind
      @cache ||= {}
      return @cache[full_key] if @cache.include? full_key
      @cache[full_key] ||= yield
    end

    def self.instance
      RequestStore.store[@per_thread_registry_key] ||= new
    end
  end
end
