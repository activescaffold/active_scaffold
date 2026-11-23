# frozen_string_literal: true

require 'openssl'

module ActiveScaffold
  module ParameterSigning
    def self.signature(data, purpose:)
      key = Rails.application.key_generator.generate_key("active_scaffold/#{purpose}/v1", 32)
      OpenSSL::HMAC.hexdigest('SHA256', key, data)
    end

    def self.valid_signature?(data, signature, purpose:)
      return false unless signature.is_a?(String) && signature.bytesize == 64

      ActiveSupport::SecurityUtils.secure_compare(self.signature(data, purpose: purpose), signature)
    end

    def self.embedded_payload(embedded, controller:)
      embedded = embedded.to_unsafe_h if embedded.respond_to?(:to_unsafe_h)
      # to_query normalizes values exactly as URL generation does. Loading is a
      # one-use rendering flag, removed after the initial embedded request.
      [controller.to_s.delete_prefix('/'), embedded.except(:loading, 'loading').to_query].to_json
    end
  end
end
