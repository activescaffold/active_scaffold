# frozen_string_literal: true

require 'securerandom'

module ActiveScaffold
  module TestSupport
    module Javascript
      module FixtureStore
        @fixtures = {}
        @mutex = Mutex.new

        class << self
          def add(html)
            id = SecureRandom.hex(16)
            @mutex.synchronize { @fixtures[id] = html.to_s }
            id
          end

          def fetch(id)
            @mutex.synchronize { @fixtures.fetch(id) }
          end

          def delete(id)
            @mutex.synchronize { @fixtures.delete(id) }
          end
        end
      end
    end
  end
end
