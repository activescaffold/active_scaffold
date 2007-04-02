module ActiveScaffold
  module Localization
    mattr_reader :lang
    def self.lang=(value)
      @@lang = standardize_name(value)
    end

    @@l10s = { 'en-us' => {} }
    @@lang = 'en-us'

    def self._(string_to_localize, *args)
      sprintf translate(string_to_localize, *args)
    end

    def self.translate(string_to_localize, *args)
      if @@l10s[@@lang].nil? or @@l10s[@@lang][string_to_localize].nil?
        string_to_localize
      else
        @@l10s[@@lang][string_to_localize]
      end
    end

    def self.define(lang = 'en-us')
      lang = standardize_name(lang)
      @@l10s[lang] ||= {}
      yield @@l10s[lang]
    end

    def self.standardize_name(value)
      tmp = value.split("-") if value["-"]
      tmp = value.split("_") if value["_"]
      tmp[0].downcase + "-" + tmp[1].downcase
    end
  end
end

class Object
  def _(*args)
    ActiveScaffold::Localization._(*args)
  end
end
