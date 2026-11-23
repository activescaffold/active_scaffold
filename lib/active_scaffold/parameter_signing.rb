# frozen_string_literal: true

require 'base64'
require 'openssl'

module ActiveScaffold
  module ParameterSigning
    TAB_SELECTION_PARAMETERS = %i[tabbed_by value value_type tab_signature].freeze
    TAB_SELECTION_FIELDS = %i[id generated_id child_association scope parent_controller eid tabbed_by value value_type].freeze

    def self.signature(data, purpose:)
      key = Rails.application.key_generator.generate_key("active_scaffold/#{purpose}/v1", 32)
      Base64.urlsafe_encode64(OpenSSL::HMAC.digest('SHA256', key, data), padding: false)
    end

    def self.valid_signature?(data, signature, purpose:)
      return false unless signature.is_a?(String) && signature.bytesize == 43

      ActiveSupport::SecurityUtils.secure_compare(self.signature(data, purpose: purpose), signature)
    end

    def self.embedded_payload(embedded, controller:)
      embedded = embedded.to_unsafe_h if embedded.respond_to?(:to_unsafe_h)
      # to_query normalizes values exactly as URL generation does. Loading is a
      # one-use rendering flag, removed after the initial embedded request.
      [controller.to_s.delete_prefix('/'), embedded.except(:loading, 'loading').to_query].to_json
    end

    def self.tab_selection_payload(options, controller:)
      fields = TAB_SELECTION_FIELDS.index_with { |key| options[key] || options[key.to_s] }
      [controller.to_s.delete_prefix('/'), fields.to_query].to_json
    end
  end
end
