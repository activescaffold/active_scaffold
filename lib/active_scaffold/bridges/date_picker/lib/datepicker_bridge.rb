class File #:nodoc:

  unless File.respond_to?(:binread)
    def self.binread(file)
      File.open(file, 'rb') { |f| f.read }
    end
  end

end 

ActiveScaffold::Config::Core.class_eval do
  def initialize_with_date_picker(model_id)
    initialize_without_date_picker(model_id)
    
    date_picker_fields = self.model.columns.collect{|c| {:name => c.name.to_sym, :type => c.type} if [:date, :datetime].include?(c.type) }.compact
    # check to see if file column was used on the model
    return if date_picker_fields.empty?
    
    # automatically set the forum_ui to a file column
    date_picker_fields.each{|field|
      col_config = self.columns[field[:name]] 
      form_ui = (field[:type] == :date ? :date_picker : :datetime_picker)
      
      col_config.form_ui = form_ui
      if col_config.options[:class]
        col_config.options[:class] += " #{form_ui.to_s} text-input"
      else
        col_config.options[:class] = "#{form_ui.to_s} text-input"
      end
    }
  end
  
  alias_method_chain :initialize, :date_picker
end


module ActiveScaffold
  module Bridges
    module DatePickerBridge
      DATE_FORMAT_CONVERSION = {
        '%a' => 'D',
        '%A' => 'DD',
        '%b' => 'M',
        '$B' => 'MM',
        '%d' => 'dd',
        '%j' => 'oo',
        '%m' => 'mm',
        '%y' => 'y',
        '%Y' => 'yy',
        '%H' => 'hh', # options ampm => false
        '%I' => 'hh', # options ampm => true
        '%M' => 'mm',
        '%p' => 'TT',
        '%S' => 'ss'
      }  
      
      def self.localization(js_file)
        localization = "jQuery(function($){
  if (typeof($.datepicker) === 'object') {
    $.datepicker.regional['#{I18n.locale}'] = #{date_options.to_json};
    $.datepicker.setDefaults($.datepicker.regional['#{I18n.locale}']);
  }
  if (typeof($.timepicker) === 'object') {
    $.timepicker.regional['#{I18n.locale}'] = #{datetime_options.to_json};
    $.timepicker.setDefaults($.timepicker.regional['#{I18n.locale}']);
  }
});\n"        
        prepend_js_file(js_file, localization)        
      end
      
      def self.date_options
        date_options = I18n.t 'date'
        date_picker_options = { :closeText => as_(:close),
          :prevText => as_(:previous),
          :nextText => as_(:next),
          :currentText => as_(:today),
          :monthNames => date_options[:month_names][1, (date_options[:month_names].length - 1)],
          :monthNamesShort => date_options[:abbr_month_names][1, (date_options[:abbr_month_names].length - 1)],
          :dayNames => date_options[:day_names],
          :dayNamesShort => date_options[:abbr_day_names],
          :dayNamesMin => date_options[:abbr_day_names],
          :changeYear => true,
          :changeMonth => true,
        }.merge(as_(:date_picker_options))
        js_format = self.date_format_converter(date_options[:formats][:default])
        date_picker_options[:dateFormat] = js_format unless js_format.nil? 
        date_picker_options
      end
      
      def self.datetime_options
        time_options = I18n.t 'time'
        datetime_options = I18n.t 'datetime.prompts'
        datetime_picker_options = {:ampm => false,
          :hourText => datetime_options[:hour],
				  :minuteText => datetime_options[:minute],
				  :secondText => datetime_options[:second],
        }.merge(as_(:datetime_picker_options))
        js_format = self.date_format_converter(time_options[:formats][:time] || '%H:%M')
        unless js_format.nil?
          datetime_picker_options[:timeFormat] = js_format 
          datetime_picker_options[:ampm] = true if time_options[:formats][:time].present? && time_options[:formats][:time].include?('%I')
        end
        datetime_picker_options
      end
      
      def self.prepend_js_file(js_file, prepend)
        content = File.binread(js_file)
        content.gsub!(/\A/, prepend)
        File.open(js_file, 'wb') { |file| file.write(content) }
      end
      
      def self.date_format_converter(rails_format)
        return nil if rails_format.nil?
        if rails_format =~ /%[cUWwxXZ]/
          Rails.logger.warn("AS DatePickerBridge: Can t convert rails date format: #{rails_format} to jquery datepicker format. Options %c, %U, %W, %w, %x %X are not supported by datepicker]")
          nil
        else
          js_format = rails_format.dup
          DATE_FORMAT_CONVERSION.each do |key, value|
            js_format.gsub!(Regexp.new("#{key}"), value)
          end
          js_format
        end
      end
      
      module SearchColumnHelpers
        def active_scaffold_search_date_bridge_calendar_control(column, options, current_search, name)
          value = controller.class.condition_value_for_datetime(current_search[name], column.column.type == :date ? :to_date : :to_time)
          options = column.options.merge(options).except!(:include_blank, :discard_time, :discard_date, :value)
          options[:class] << " #{column.options[:class]}" if column.options[:class]
          text_field_tag("#{options[:name]}[#{name}]", value ? l(value) : nil, options.merge(:id => "#{options[:id]}_#{name}", :name => "#{options[:name]}[#{name}]"))
        end
      end
      
      module FormColumnHelpers
        def active_scaffold_input_date_picker(column, options)
          options = active_scaffold_input_text_options(options)
          value = controller.class.condition_value_for_datetime(@record.send(column.name), column.column.type == :date ? :to_date : :to_time)
          options[:value] = (value ? l(value) : nil)
          Rails.logger.info("column.name: #{column.name}: #{options[:value]}")
          text_field(:record, column.name, options.merge(column.options))
        end
      end
    end
  end
end

ActionView::Base.class_eval do
  include ActiveScaffold::Bridges::Shared::DateBridge::SearchColumnHelpers
  alias_method :active_scaffold_search_datetime, :active_scaffold_search_date_bridge
  include ActiveScaffold::Bridges::DatePickerBridge::SearchColumnHelpers
  include ActiveScaffold::Bridges::DatePickerBridge::FormColumnHelpers
  alias_method :active_scaffold_input_datetime_picker, :active_scaffold_input_date_picker
end
ActiveScaffold::Finder::ClassMethods.module_eval do
  include ActiveScaffold::Bridges::Shared::DateBridge::Finder::ClassMethods
  alias_method :condition_for_date_picker_type, :condition_for_date_bridge_type
  alias_method :condition_for_datetime_picker_type, :condition_for_date_picker_type
  alias_method :human_condition_for_date_picker_type, :human_condition_for_date_bridge_type
  alias_method :human_condition_for_datetime_picker_type, :human_condition_for_date_bridge_type
end
