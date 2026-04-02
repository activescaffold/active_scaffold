# frozen_string_literal: true

module ActiveScaffold::Bridges
  class CountrySelect
    module FormColumnHelpers
      def active_scaffold_input_country(column, options, ui_options: column.options)
        select_options = {prompt: as_(:_select_), priority_countries: ui_options[:priority] || [:us]}
        select_options[:format] = ui_options[:format] if ui_options[:format]
        select_options.merge!(options)
        options.reverse_merge!(ui_options).except!(:prompt, :priority, :format)
        active_scaffold_select_name_with_multiple options
        country_select(:record, column.name, select_options, options.except(:object))
      end
    end

    module ListColumnHelpers
      def active_scaffold_column_country(record, column, ui_options: column.options)
        country_code = record.send(column.name)
        return if country_code.blank?

        country = ISO3166::Country[country_code]
        return country_code unless country

        country.translations[I18n.locale.to_s] || country.name
      end
    end

    module SearchColumnHelpers
      def active_scaffold_search_country(column, options, ui_options: column.options)
        active_scaffold_input_country(column, options.merge!(selected: options.delete(:value)), ui_options: ui_options)
      end
    end
  end
end

# To use old way, saving country name instead of CountrySelect default of country code
CountrySelect::FORMATS[:old] = ->(country) { [country.translations[I18n.locale.to_s] || country.name, country.name] }

ActionView::Base.class_eval do
  include ActiveScaffold::Bridges::CountrySelect::FormColumnHelpers
  include ActiveScaffold::Bridges::CountrySelect::ListColumnHelpers
  include ActiveScaffold::Bridges::CountrySelect::SearchColumnHelpers
end
