module ActiveScaffold
  module Bridges
    class CalendarDateSelect
      module CalendarDateSelectBridge
        def initialize(model_id)
          initialize_without_calendar_date_select(model_id)

          calendar_date_select_fields = _columns.collect { |c| c.name.to_sym if %i[date datetime].include?(c.type) }.compact
          # check to see if file column was used on the model
          return if calendar_date_select_fields.empty?

          # automatically set the forum_ui to a file column
          calendar_date_select_fields.each { |field| columns[field].form_ui = :calendar_date_select }
        end
      end

      # Helpers that assist with the rendering of a Form Column
      module FormColumnHelpers
        def active_scaffold_input_calendar_date_select(column, options, ui_options: column.options)
          options[:class] = "#{options[:class]} text-input".strip
          calendar_date_select('record', column.name, options.merge(ui_options))
        end
      end

      module SearchColumnHelpers
        def active_scaffold_search_calendar_date_select_field(column, options, current_search, name, ui_options: column.options)
          value =
            if current_search.is_a? Hash
              controller.class.condition_value_for_datetime(column, current_search[name], column.column.type == :date ? :to_date : :to_time)
            else
              current_search
            end
          calendar_date_select(
            'record', column.name,
            :name => "#{options[:name]}[#{name}]",
            :value => (value ? l(value) : nil),
            :class => 'text-input',
            :id => "#{options[:id]}_#{name}",
            :time => column_datetime?(column) ? true : false,
            :style => ('display: none' if options[:show] == false) # hide only if asked to hide
          )
        end
      end
    end
  end
end

ActionView::Base.class_eval do
  include ActiveScaffold::Bridges::CalendarDateSelect::FormColumnHelpers
  alias_method :active_scaffold_search_calendar_date_select, :active_scaffold_search_datetime
  alias_method :active_scaffold_human_condition_calendar_date_select, :active_scaffold_human_condition_datetime
  include ActiveScaffold::Bridges::CalendarDateSelect::SearchColumnHelpers
end

ActiveScaffold::Finder::ClassMethods.module_eval do
  alias_method :condition_for_calendar_date_select_type, :condition_for_datetime
end
ActiveScaffold::Config::Core.send :prepend, ActiveScaffold::Bridges::CalendarDateSelect::CalendarDateSelectBridge
