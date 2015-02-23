class Object
  def as_(key, options = {})
    unless key.blank?
      text = I18n.translate("#{key}", {:scope => [:active_scaffold, *options.delete(:scope)], :default => key.is_a?(String) ? key : key.to_s.titleize}.merge(options)).html_safe
      # text = nil if text.include?('translation missing:')
    end
    text ||= key
    text
  end
end
