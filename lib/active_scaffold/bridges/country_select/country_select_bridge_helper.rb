module ActiveScaffold::Bridges
  class CountrySelect
    module FormColumnHelpers
      def active_scaffold_input_country(column, options)
        select_options = {:prompt => as_(:_select_), :priority_countries => column.options[:priority] || [:us], :format => column.options[:format]}
        select_options.merge!(options)
        options.reverse_merge!(column.options).except!(:prompt, :priority, :format)
        options[:name] += '[]' if options[:multiple]
        country_select(:record, column.name, select_options, options.except(:object))
      end
    end

    module ListColumnHelpers
      def active_scaffold_column_country(record, column)
        country_code = record.send(column.name)
        return if country_code.blank?
        country = ISO3166::Country[country_code]
        return country_code unless country
        country.translations[I18n.locale.to_s] || country.name
      end
    end

    module SearchColumnHelpers
      def active_scaffold_search_country(column, options)
        active_scaffold_input_country(column, options.merge!(:selected => options.delete(:value)))
      end
    end
  end
end

# To use old way, saving country name instead of CountrySelect default of country code
CountrySelect::FORMATS[:old] = lambda { |country| [country.translations[I18n.locale.to_s] || country.name, country.name] }

ActionView::Base.class_eval do
  include ActiveScaffold::Bridges::CountrySelect::FormColumnHelpers
  include ActiveScaffold::Bridges::CountrySelect::ListColumnHelpers
  include ActiveScaffold::Bridges::CountrySelect::SearchColumnHelpers
end
