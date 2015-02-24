module ActiveScaffold
  module DateSelectExtension
    def datetime_selector_with_name(options, html_options)
      options.merge!(:prefix => options[:name].gsub(/\[[^\[]*\]$/, '')) if options[:name]
      datetime_selector_without_name(options, html_options)
    end
    def self.included(base)
      base.class_eval do
        alias_method_chain :datetime_selector, :name
        private :datetime_selector_without_name, :datetime_selector_with_name, :datetime_selector
      end
    end
  end
end
(defined?(ActionView::Helpers::Tags::DateSelect) ? ActionView::Helpers::Tags::DateSelect : ActionView::Helpers::InstanceTag).class_eval do
  include ActiveScaffold::DateSelectExtension
end
