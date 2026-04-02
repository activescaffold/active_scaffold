# frozen_string_literal: true

module ActiveScaffold
  module Testing
    module AssertEmbeddedLoad
      def assert_embedded_load(selector = nil, **options)
        elements = []
        full_selector = [selector, '.active-scaffold-component a.load-embedded[href]'].compact.join(' ')

        # Collect elements without failing if none found, unless user wanted with options
        assert_select(full_selector, **options) do |matches|
          elements = matches
        end

        # Run GET on each href
        elements.each do |el|
          get el['href']
          assert_successful_response!
        end
      end

      def assert_successful_response!
        if respond_to?(:assert_response)
          assert_response :success
        elsif defined?(RSpec)
          expect(response).to have_http_status(:ok)
        else
          raise 'No known assertion method for response'
        end
      end
    end
  end
end
