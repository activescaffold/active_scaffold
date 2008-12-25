class Object
  def as_(key, options = {})
    unless key.blank?
      text = I18n.translate "#{key}", {:scope => [:active_scaffold]}.merge(options)
      # text = nil if text.include?('translation missing:')
    end
    text ||= key 
    text
  end
end
