module ActiveScaffold
  module Localization
    mattr_reader :lang
    def self.lang=(value)
      @@lang = standardize_name(value)
    end

    @@l10s = { 'en-us' => {} }
    @@lang = 'en-us'

    def self._(string_to_localize, *args)
      sprintf translate(string_to_localize, args), args
    end

    # use a hash format for pluralization:
    # keys are integers that represents the minimum count to match in order to be used
    # the hash must have a 1 (singular) format (returned when pluralization is bypassed by empty args)
    # the hash can have unlimited pluralization cases, and one optional nullar case
    # if nullar (0) is omitted the singular (1) form is used bu default
    # example of format: { 0=>'nullar %d', 1=>'singular %d', 2=>'dual %d', 3=>"paucal %d", 5=>'plural %d'}
    # empty/nil args will bypass the pluralization in order to be used with external i18n plugins
    def self.translate(string_to_localize, args=[])
      if @@l10s[@@lang].nil? or @@l10s[@@lang][string_to_localize].nil?
        string_to_localize
      else
        format = @@l10s[@@lang][string_to_localize]
        if format.is_a?(String)  # pluralization not required; args ignored here
          format
        elsif format.is_a?(Hash) # pluralization required
          if args.empty?         # pluralization bypassed
            format[1]            # singular returned
          else                   # pluraliztion 
            count = (args.select{|i| i.is_a?(Numeric)}).first  # finds the count in args
            key = (format.keys.sort.reverse.select{|v| v <= count}).first # finds the case 
            key = format.keys.sort.first if key.nil?  # when nullar is omitted and count == 0
            format[key] # pluralized format returned
          end
        else # something wrong in the format
          string_to_localize
        end
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
