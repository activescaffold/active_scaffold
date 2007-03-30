module ActiveScaffold
  module Localization
    mattr_reader :lang
    def self.lang=(value)
      @@lang = standardize_name(value)
    end

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
      lang = standardize_name(lang)
      @@l10s[lang] ||= {}
      yield @@l10s[lang]
    end

    def self.standardize_name(value)
      tmp = value.split("-") if value["-"]
      tmp = value.split("_") if value["_"]
      tmp[0].downcase + "_" + tmp[1].upcase
    end
  end
end

class Object
  def _(*args)
    ActiveScaffold::Localization._(*args)
  end
end
