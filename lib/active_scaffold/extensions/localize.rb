class Object
  def as_(key, options = {})
    if key.present?
      text = I18n.translate(key.to_s, {:scope => [:active_scaffold, *options.delete(:scope)], :default => key.is_a?(String) ? key : key.to_s.titleize}.merge(options)).html_safe # rubocop:disable Rails/OutputSafety
      # text = nil if text.include?('translation missing:')
    end
    text || key
  end
end
