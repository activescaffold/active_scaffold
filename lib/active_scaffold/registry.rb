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
  end
end