module ActiveScaffold::Bridges
  class UsaStateSelect
    module UsaStateSelectHelpers
      def usa_state_select_options(options)
        # TODO remove when rails 3.2 support is dropped
        defined?(ActionView::Helpers::InstanceTag) ? options[:object] : options
      end

      def usa_state_select(object, method, priority_states = nil, options = {}, html_options = {})
        ActionView::Helpers::Tags::UsaStateSelect.new(object, method, self, usa_state_select_options(options)).to_usa_state_select_tag(priority_states, options, html_options)
      end
    end

    module UsaStateSelectOptionsHelpers
      # Returns a string of option tags for the states in the United States. Supply a state name as +selected to
      # have it marked as the selected option tag. Included also is the option to set a couple of +priority_states+
      # in case you want to highligh a local area
      # NOTE: Only the option tags are returned from this method, wrap it in a <select>
      def usa_state_options_for_select(selected = nil, priority_states = nil)
        if priority_states
          state_options = options_for_select(priority_states + [['-------------', '']], :selected => selected, :disabled => '')
        else
          state_options = options_for_select([])
        end

        if priority_states && priority_states.include?(selected)
          state_options += options_for_select(USASTATES - priority_states, :selected => selected)
        else
          state_options += options_for_select(USASTATES, :selected => selected)
        end

        state_options
      end

      USASTATES = [%w(Alabama AL), %w(Alaska AK), %w(Arizona AZ), %w(Arkansas AR), %w(California CA), %w(Colorado CO), %w(Connecticut CT), %w(Delaware DE), ['District of Columbia', 'DC'], %w(Florida FL), %w(Georgia GA), %w(Hawaii HI), %w(Idaho ID), %w(Illinois IL), %w(Indiana IN), %w(Iowa IA), %w(Kansas KS), %w(Kentucky KY), %w(Louisiana LA), %w(Maine ME), %w(Maryland MD), %w(Massachusetts MA), %w(Michigan MI), %w(Minnesota MN), %w(Mississippi MS), %w(Missouri MO), %w(Montana MT), %w(Nebraska NE), %w(Nevada NV), ['New Hampshire', 'NH'], ['New Jersey', 'NJ'], ['New Mexico', 'NM'], ['New York', 'NY'], ['North Carolina', 'NC'], ['North Dakota', 'ND'], %w(Ohio OH), %w(Oklahoma OK), %w(Oregon OR), %w(Pennsylvania PA), ['Rhode Island', 'RI'], ['South Carolina', 'SC'], ['South Dakota', 'SD'], %w(Tennessee TN), %w(Texas TX), %w(Utah UT), %w(Vermont VT), %w(Virginia VA), %w(Washington WA), %w(Wisconsin WI), ['West Virginia', 'WV'], %w(Wyoming WY)] unless const_defined?('USASTATES')
    end

    module InstanceTagMethods
      def to_usa_state_select_tag(priority_states, options, html_options)
        html_options = html_options.stringify_keys
        add_default_name_and_id(html_options)
        value = value(object)
        selected_value = options.key?(:selected) ? options[:selected] : value
        content_tag('select', add_options(usa_state_options_for_select(selected_value, priority_states), options, selected_value), html_options)
      end
    end

    module FormColumnHelpers
      def active_scaffold_input_usa_state(column, options)
        select_options = {:prompt => as_(:_select_)}
        select_options.merge!(options)
        options.reverse_merge!(column.options).except!(:prompt, :priority)
        options[:name] += '[]' if options[:multiple]
        usa_state_select(:record, column.name, column.options[:priority], select_options, options.except(:object))
      end
    end

    module SearchColumnHelpers
      def active_scaffold_search_usa_state(column, options)
        active_scaffold_input_usa_state(column, options.merge!(:selected => options.delete(:value)))
      end
    end
  end
end

ActionView::Base.class_eval do
  include ActiveScaffold::Bridges::UsaStateSelect::UsaStateSelectHelpers
  include ActiveScaffold::Bridges::UsaStateSelect::UsaStateSelectOptionsHelpers
  include ActiveScaffold::Bridges::UsaStateSelect::FormColumnHelpers
  include ActiveScaffold::Bridges::UsaStateSelect::SearchColumnHelpers
end
if defined? ActionView::Helpers::InstanceTag # TODO remove when rails 3.2 support is dropped
  module ActionView::Helpers::Tags
    class UsaStateSelect < ActionView::Helpers::InstanceTag
      include ActiveScaffold::Bridges::UsaStateSelect::UsaStateSelectOptionsHelpers
      include ActiveScaffold::Bridges::UsaStateSelect::InstanceTagMethods
    end
  end
else
  class ActionView::Helpers::Tags::UsaStateSelect < ActionView::Helpers::Tags::Base #:nodoc:
    include ActiveScaffold::Bridges::UsaStateSelect::UsaStateSelectOptionsHelpers
    include ActiveScaffold::Bridges::UsaStateSelect::InstanceTagMethods
  end
end
