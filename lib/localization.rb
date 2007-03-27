module Localization
  mattr_accessor :lang

  @@l10s = { 'en_US' => {} }
  @@lang = 'en_US'

  def self._(string_to_localize, *args)
    if @@l10s[@@lang].nil? or @@l10s[@@lang][string_to_localize].nil?
      translated = string_to_localize
    else
      translated = @@l10s[@@lang][string_to_localize]
    end
    return translated.call(*args).to_s  if translated.is_a? Proc
    if translated.is_a? Array
      translated = if translated.size == 3
        translated[args[0]==0 ? 0 : (args[0]>1 ? 2 : 1)]
      else
        translated[args[0]>1 ? 1 : 0]
      end
    end
    sprintf translated, *args
  end

  def self.define(lang = 'en_US')
    @@l10s[lang] ||= {}
    yield @@l10s[lang]
  end

end

class Object
  def _(*args)
    Localization._(*args)
  end
end
