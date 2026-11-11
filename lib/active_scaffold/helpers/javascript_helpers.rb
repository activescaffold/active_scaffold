# frozen_string_literal: true

module ActiveScaffold
  module Helpers
    # Helpers for safely embedding Ruby values in JavaScript responses.
    module JavascriptHelpers
      # Serialize a Ruby value for direct insertion into generated JavaScript code.
      # The result is a complete JavaScript literal, so do not add surrounding quotes.
      def javascript_literal(value)
        json = ActiveSupport::JSON.encode(value)
        ERB::Util.json_escape(json).html_safe # rubocop:disable Rails/OutputSafety
      end
    end
  end
end
