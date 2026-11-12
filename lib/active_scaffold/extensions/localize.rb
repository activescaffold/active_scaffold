# frozen_string_literal: true

require 'active_scaffold/translation_html_safety'

class Object
  def as_(key, options = {})
    if key.present?
      options = options.merge(scope: [:active_scaffold, *options[:scope]])
      options[:default] = key.is_a?(String) ? key : key.to_s.titleize unless options.key?(:default)

      missing_html_translation = Object.new
      html = I18n.t("#{key}.html", **options, default: missing_html_translation)
      text =
        if html.equal?(missing_html_translation)
          translation = I18n.t(key.to_s, **options)
          ActiveScaffold::TranslationHtmlSafety.check_once(key, options[:scope], translation) if translation.is_a?(String)
          translation.html_safe # rubocop:disable Rails/OutputSafety
        else
          html.html_safe # rubocop:disable Rails/OutputSafety
        end
    end
    text || key
  end
end
