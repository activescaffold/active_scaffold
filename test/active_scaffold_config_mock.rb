# frozen_string_literal: true

module ActiveScaffoldConfigMock
  module ClassMethods
    class Config
      def active_record?
        @type == :active_record
      end

      def mongoid?
        @type == :mongoid
      end

      def initialize(type = :active_record)
        @type = type
      end

      def primary_key
        mongoid? ? '_id' : 'id'
      end
    end

    def active_scaffold_config
      @active_scaffold_config ||= Config.new
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end

  delegate :active_scaffold_config, to: :class
end
