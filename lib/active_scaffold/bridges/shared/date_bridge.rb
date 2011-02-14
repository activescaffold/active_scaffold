module ActiveScaffold
  module Bridges
    module Shared
      module DateBridge
        module SearchColumnHelpers
          def active_scaffold_search_date_bridge(column, options)
            current_search = {'from' => nil, 'to' => nil, 'opt' => 'BETWEEN',
                              'number' => 1, 'unit' => 'DAYS', 'range' => nil}
            current_search.merge!(options[:value]) unless options[:value].nil?
            tags = []
            tags << active_scaffold_search_date_bridge_comparator_tag(column, options, current_search)
            tags << active_scaffold_search_date_bridge_trend_tag(column, options, current_search)
            tags << active_scaffold_search_date_bridge_numeric_tag(column, options, current_search)
            tags << active_scaffold_search_date_bridge_range_tag(column, options, current_search)
            tags.join("&nbsp;").html_safe
          end
          
          def active_scaffold_search_date_bridge_comparator_options(column)
            select_options = ActiveScaffold::Finder::DateComparators.collect {|comp| [as_(comp.downcase.to_sym), comp]}
            select_options + ActiveScaffold::Finder::NumericComparators.collect {|comp| [as_(comp.downcase.to_sym), comp]}
          end
          
          def active_scaffold_search_date_bridge_comparator_tag(column, options, current_search)
            select_tag("#{options[:name]}[opt]", options_for_select(active_scaffold_search_date_bridge_comparator_options(column),current_search['opt']), :id => "#{options[:id]}_opt", :class => "as_search_range_option as_search_date_time_option")
          end
          
          def active_scaffold_search_date_bridge_numeric_tag(column, options, current_search)
            numeric_controls = "" << 
            active_scaffold_search_date_bridge_calendar_control(column, options, current_search, 'from') <<
            content_tag(:span, (" - " + active_scaffold_search_date_bridge_calendar_control(column, options, current_search, 'to')).html_safe,
              :id => "#{options[:id]}_between", :class => "as_search_range_between", :style => "display:#{current_search['opt'] == 'BETWEEN' ? '' : 'none'}")  
            content_tag("span", numeric_controls.html_safe, :id => "#{options[:id]}_numeric", :style => "display:#{ActiveScaffold::Finder::NumericComparators.include?(current_search['opt']) ? '' : 'none'}")
          end
  
          def active_scaffold_search_date_bridge_trend_tag(column, options, current_search)
            active_scaffold_date_bridge_trend_tag(column, options, 
                                                 {:name_prefix => 'search',
                                                  :number_value => current_search['number'],
                                                  :unit_value => current_search["unit"],
                                                  :show => (current_search['opt'] == 'PAST' || current_search['opt'] == 'FUTURE')})
          end

          def active_scaffold_date_bridge_trend_tag(column, options, trend_options)
            trend_controls = text_field_tag("#{trend_options[:name_prefix]}[#{column.name}][number]", trend_options[:number_value], :class => 'text-input', :size => 10, :autocomplete => 'off') << " " <<
            select_tag("#{trend_options[:name_prefix]}[#{column.name}][unit]",
             options_for_select(active_scaffold_search_date_bridge_trend_units(column), trend_options[:unit_value]),
             :class => 'text-input')
            content_tag("span", trend_controls.html_safe, :id => "#{options[:id]}_trend", :style => "display:#{trend_options[:show] ? '' : 'none'}")
          end

          def active_scaffold_search_date_bridge_trend_units(column)
             options = ActiveScaffold::Finder::DateUnits.collect{|unit| [as_(unit.downcase.to_sym), unit]}
             options = ActiveScaffold::Finder::TimeUnits.collect{|unit| [as_(unit.downcase.to_sym), unit]} + options if column_datetime?(column)
             options
          end
          
          def active_scaffold_search_date_bridge_range_tag(column, options, current_search)
            range_controls = select_tag("search[#{column.name}][range]", 
              options_for_select( ActiveScaffold::Finder::DateRanges.collect{|range| [as_(range.downcase.to_sym), range]}, current_search["range"]), 
             :class => 'text-input')
            content_tag("span", range_controls.html_safe, :id => "#{options[:id]}_range", :style => "display:#{(current_search['opt'] == 'RANGE') ? '' : 'none'}")
          end
          
          def column_datetime?(column)
            (!column.column.nil? && [:datetime, :time].include?(column.column.type))
          end
        end

        module HumanConditionHelpers
          def active_scaffold_human_condition_date_bridge(column, value)
            case value[:opt]
            when 'RANGE'
              range_type, range = value[:range].downcase.split('_')
              format = active_scaffold_human_condition_date_bridge_range_format(range_type, range)
              from, to = controller.class.date_bridge_from_to(column, value)
              "#{column.active_record_class.human_attribute_name(column.name)} = #{as_(value[:range].downcase).downcase} (#{I18n.l(from, :format => format)})"
            when 'PAST', 'FUTURE'
              from, to = controller.class.date_bridge_from_to(column, value)
              "#{column.active_record_class.human_attribute_name(column.name)} #{as_('BETWEEN'.downcase).downcase} #{I18n.l(from)} - #{I18n.l(to)}"
            else
              from, to = controller.class.date_bridge_from_to(column, value)
              "#{column.active_record_class.human_attribute_name(column.name)} #{as_(value[:opt].downcase).downcase} #{I18n.l(from)} #{value[:opt] == 'BETWEEN' ? '- ' + I18n.l(to) : ''}"
            end
          end

          def active_scaffold_human_condition_date_bridge_range_format(range_type, range)
            case range
            when 'week'
              first_day_of_week = I18n.translate 'active_scaffold.date_picker_options.firstDay'
              if first_day_of_week == 1
                '%W %Y'
              else
                '%U %Y'
              end
            when 'month'
              '%b %Y'
            when 'year'
              '%Y'
            else
              I18n.translate 'date.formats.default'
            end
          end
        end
        
        module Finder
          module ClassMethods
            def condition_for_date_bridge_type(column, value, like_pattern)
              operator = ActiveScaffold::Finder::NumericComparators.include?(value[:opt]) && value[:opt] != 'BETWEEN' ? value[:opt] : nil
              from_value, to_value = date_bridge_from_to(column, value)
              
              if column.search_sql.is_a? Proc
                column.search_sql.call(from_value, to_value, operator)
              else
                unless operator.nil?
                  ["#{column.search_sql} #{value[:opt]} ?", from_value.to_s(:db)] unless from_value.nil?
                else
                  ["#{column.search_sql} BETWEEN ? AND ?", from_value.to_s(:db), to_value.to_s(:db)] unless from_value.nil? && to_value.nil?  
                end
              end
            end
            
            def date_bridge_from_to(column, value)
              conversion = column.column.type == :date ? :to_date : :to_time
              case value[:opt]
              when 'RANGE'
                date_bridge_from_to_for_range(column, value).collect(&conversion)
              when 'PAST', 'FUTURE'
                date_bridge_from_to_for_trend(column, value).collect(&conversion)
              else
                ['from', 'to'].collect { |field| condition_value_for_datetime(value[field], conversion)}
              end
            end

            def date_bridge_now
              Time.zone.now
            end
            
            def date_bridge_from_to_for_trend(column, value)
              case value['opt']
              when "PAST"
                trend_number = [value['number'].to_i,  1].max
                now = date_bridge_now
                if date_bridge_column_date?(column)
                  from = now.beginning_of_day.ago((trend_number).send(value['unit'].downcase.singularize.to_sym))
                  to = now.end_of_day
                else
                  from = now.ago((trend_number).send(value['unit'].downcase.singularize.to_sym))
                  to = now
                end
                return from, to
              when "FUTURE"
                trend_number = [value['number'].to_i,  1].max
                now = date_bridge_now
                if date_bridge_column_date?(column)
                  from = now.beginning_of_day
                  to = now.end_of_day.in((trend_number).send(value['unit'].downcase.singularize.to_sym))
                else
                  from = now
                  to = now.in((trend_number).send(value['unit'].downcase.singularize.to_sym))
                end
                return from, to
              end
            end
            
            def date_bridge_from_to_for_range(column, value)
              case value[:range]
              when 'TODAY'
                return date_bridge_now.beginning_of_day, date_bridge_now.end_of_day
              when 'YESTERDAY'
                return date_bridge_now.ago(1.day).beginning_of_day, date_bridge_now.ago(1.day).end_of_day
              when 'TOMORROW'
                return date_bridge_now.in(1.day).beginning_of_day, date_bridge_now.in(1.day).end_of_day
              else
                range_type, range = value[:range].downcase.split('_')
                raise ArgumentError unless ['week', 'month', 'year'].include?(range)
                case range_type
                when 'this'
                  return date_bridge_now.send("beginning_of_#{range}".to_sym), date_bridge_now.send("end_of_#{range}")
                when 'prev'
                  return date_bridge_now.ago(1.send(range.to_sym)).send("beginning_of_#{range}".to_sym), date_bridge_now.ago(1.send(range.to_sym)).send("end_of_#{range}".to_sym)
                when 'next'
                  return date_bridge_now.in(1.send(range.to_sym)).send("beginning_of_#{range}".to_sym), date_bridge_now.in(1.send(range.to_sym)).send("end_of_#{range}".to_sym)
                else
                  return nil, nil    
                end
              end
            end

            def date_bridge_column_date?(column)
              if [:date_picker, :datetime_picker].include? column.form_ui
                column.form_ui == :date_picker
              else
                (!column.column.nil? && [:date].include?(column.column.type))
              end
            end
          end
        end
      end
    end
  end
end

ActiveScaffold::Finder.const_set('DateComparators', ["PAST", "FUTURE", "RANGE"])
ActiveScaffold::Finder.const_set('DateUnits', ["DAYS", "WEEKS", "MONTHS", "YEARS"])
ActiveScaffold::Finder.const_set('TimeUnits', ["SECONDS", "MINUTES", "HOURS"])
ActiveScaffold::Finder.const_set('DateRanges', ["TODAY", "YESTERDAY", "TOMORROW",
                                                "THIS_WEEK", "PREV_WEEK", "NEXT_WEEK",
                                                "THIS_MONTH", "PREV_MONTH", "NEXT_MONTH",
                                                "THIS_YEAR", "PREV_YEAR", "NEXT_YEAR"])