# frozen_string_literal: true

class Object
  def as_(key, options = {})
    if key.present?
      scope = [:active_scaffold, *options.delete(:scope)]
      options = options.reverse_merge(scope: scope, default: key.is_a?(String) ? key : key.to_s.titleize)
      text = I18n.t(key.to_s, **options).html_safe
      # text = nil if text.include?('translation missing:')
    end
    text || key
  end
end
