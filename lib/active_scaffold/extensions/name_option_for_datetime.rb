# frozen_string_literal: true

module ActiveScaffold
  module DateSelectExtension
    private

    def datetime_selector(options, html_options)
      options[:prefix] = options[:name].gsub(/\[[^\[]*\]$/, '') if options[:name]
      super
    end
  end
end
ActionView::Helpers::Tags::DateSelect.class_eval do
  prepend ActiveScaffold::DateSelectExtension
end
