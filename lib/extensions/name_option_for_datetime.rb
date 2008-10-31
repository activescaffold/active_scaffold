module ActionView
  module Helpers
    class InstanceTag
      # patch an issue with integer size parameters
      def to_text_area_tag(options = {})
        options = DEFAULT_TEXT_AREA_OPTIONS.merge(options.stringify_keys)
        add_default_name_and_id(options)

        if size = options.delete("size")
          options["cols"], options["rows"] = size.split("x") if size.class == String
        end

        if method(:value_before_type_cast).arity > 0
          content_tag("textarea", html_escape(options.delete('value') || value_before_type_cast(object)), options)
        else
          content_tag("textarea", html_escape(options.delete('value') || value_before_type_cast), options)
        end
      end

      private
      # patch in support for options[:name]
      def datetime_selector_with_name(options, html_options)
        datetime = value(object) || default_datetime(options)

        options = options.dup
        options[:field_name]           = @method_name
        options[:include_position]     = true
        options[:prefix]             ||= @object_name
        options[:index]              ||= @auto_index
        options[:datetime_separator] ||= ' &mdash; '
        options[:time_separator]     ||= ' : '
        options.merge(:prefix => options[:name].dup.insert(-2, "(#{position}i)")) if options[:name]

        DateTimeSelector.new(datetime, options.merge(:tag => true), html_options)
      end
      alias_method_chain :datetime_selector, :name
    end
  end
end