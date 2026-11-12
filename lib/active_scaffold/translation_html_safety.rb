# frozen_string_literal: true

require 'concurrent/map'

module ActiveScaffold
  module TranslationHtmlSafety
    HTML_PATTERN = /<[^>]+>|&(?:[a-z][a-z0-9]+|#\d+|#x[0-9a-f]+);/i

    @checked_translations = Concurrent::Map.new

    class << self
      def check_once(key, scope, translation)
        translation_key_parts = [*scope, key].freeze
        return unless @checked_translations.put_if_absent(translation_key_parts, true).nil?
        return unless translation.match?(HTML_PATTERN)

        translation_key = translation_key_parts.join('.')
        ActiveScaffold.deprecator.warn(
          "HTML in translation #{translation_key} is deprecated. Move it to #{translation_key}.html. " \
          'Ordinary translations will no longer be marked HTML-safe in ActiveScaffold 4.5.'
        )
      end
    end
  end
end
