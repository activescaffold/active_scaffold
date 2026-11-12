# frozen_string_literal: true

require 'active_support/html_safe_translation'

class Object
  def as_(key, options = {})
    if key.present?
      options = options.merge(scope: [:active_scaffold, *options[:scope]])
      options[:default] = key.is_a?(String) ? key : key.to_s.titleize unless options.key?(:default)

      missing_html_translation = Object.new
      html = ActiveSupport::HtmlSafeTranslation.translate(
        "#{key}.html", **options, default: missing_html_translation
      )
      text =
        if html.equal?(missing_html_translation)
          I18n.t(key.to_s, **options)
        else
          html
        end
    end
    text || key
  end
end
