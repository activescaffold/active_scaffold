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
            trend_controls = text_field_tag("search[#{column.name}][number]", current_search['number'], :class => 'text-input', :size => 10) << " " << 
            select_tag("search[#{column.name}][unit]", 
             options_for_select( ActiveScaffold::Finder::DateUnits.collect{|date_unit| [as_(date_unit.downcase.to_sym), date_unit]}, current_search["unit"]), 
             :class => 'text-input')
            content_tag("span", trend_controls.html_safe, :id => "#{options[:id]}_trend", :style => "display:#{(current_search['opt'] == 'PAST' || current_search['opt'] == 'FUTURE') ? '' : 'none'}")
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
            
            def date_bridge_from_to_for_trend(column, value)
              case value['opt']
              when "PAST"
                trend_number = [value['number'].to_i,  1].max
                return eval("Time.zone.now.beginning_of_#{value['unit'].downcase.singularize}.ago(#{trend_number - 1}.#{value['unit'].downcase.singularize})"), Time.zone.now.end_of_day
              when "FUTURE"
                trend_number = [search_criterion['number'].to_i,  1].max
                return Time.zone.now.beginning_of_day, eval("Time.zone.now.end_of_#{value['unit'].downcase.singularize}.in(#{trend_number - 1}.#{value['unit'].downcase.singularize})")
              end
            end
            
            def date_bridge_from_to_for_range(column, value)
              case value[:range]
              when 'TODAY'
                return Time.zone.now.beginning_of_day, Time.zone.now.end_of_day
              when 'YESTERDAY'
                return Time.zone.now.ago(1.day).beginning_of_day, Time.zone.now.ago(1.day).end_of_day
              when 'TOMMORROW'
                return Time.zone.now.in(1.day).beginning_of_day, Time.zone.now.in(1.day).end_of_day
              else
                range_type, range = value[:range].downcase.split('_')
                raise ArgumentError unless ['week', 'month', 'year'].include?(range)
                case range_type
                when 'this'
                  return Time.zone.now.send("beginning_of_#{range}".to_sym), Time.zone.now.send("end_of_#{range}")
                when 'prev'
                  return Time.zone.now.ago(1.send(range.to_sym)).send("beginning_of_#{range}".to_sym), Time.zone.now.ago(1.send(range.to_sym)).send("end_of_#{range}".to_sym)
                when 'next'
                  return Time.zone.now.in(1.send(range.to_sym)).send("beginning_of_#{range}".to_sym), Time.zone.now.in(1.send(range.to_sym)).send("end_of_#{range}".to_sym)
                else
                  return nil, nil    
                end
              end
            end
            
            def human_condition_for_date_bridge_type(column, value)
              case value[:opt]
              when 'RANGE'
                "#{column.active_record_class.human_attribute_name(column.name)} = #{as_(value[:range]).downcase}"
              when 'PAST', 'FUTURE'
                "#{column.active_record_class.human_attribute_name(column.name)} #{as_(value[:opt]).downcase} #{as_(value[:number])} #{as_(value[:unit]).downcase}"
              else
                from, to = date_bridge_from_to(column, value)
                "#{column.active_record_class.human_attribute_name(column.name)} #{as_(value[:opt]).downcase} #{I18n.l(from)} #{value[:opt] == 'BETWEEN' ? '-' + I18n.l(to) : ''}"
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
ActiveScaffold::Finder.const_set('DateRanges', ["TODAY", "YESTERDAY", "TOMORROW",
                                                "THIS_WEEK", "PREV_WEEK", "NEXT_WEEK",
                                                "THIS_MONTH", "PREV_MONTH", "NEXT_MONTH",
                                                "THIS_YEAR", "PREV_YEAR", "NEXT_YEAR"])




