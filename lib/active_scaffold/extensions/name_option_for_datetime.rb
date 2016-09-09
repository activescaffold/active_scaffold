module ActiveScaffold
  module WithName
    def datetime_selector(options, html_options)
      options[:prefix] = options[:name].gsub(/\[[^\[]*\]$/, '') if options[:name]
      super(options, html_options)
    end
  end

  module DateSelectExtension
    def self.included(base)
      base.prepend WithName
    end
  end
end
(defined?(ActionView::Helpers::Tags::DateSelect) ? ActionView::Helpers::Tags::DateSelect : ActionView::Helpers::InstanceTag).class_eval do
  include ActiveScaffold::DateSelectExtension
end
