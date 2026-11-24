# frozen_string_literal: true

require 'concurrent/map'

module ActiveScaffold
  module ParameterFilterWarning
    @warned_controllers = Concurrent::Map.new

    def self.warn_once(controller)
      key = controller.name || controller
      return unless @warned_controllers.put_if_absent(key, true).nil?

      ActiveScaffold.deprecator.warn(
        "#{controller}: conditions_from_params implicitly allows filtering on all database columns, " \
        'including hidden or unauthorized values that can be inferred from matching records or counts. ' \
        'In ActiveScaffold 4.5, conditions_from_params_allowed_columns will default to [], disabling ' \
        'these filters. Configure conditions_from_params_allowed_columns or ' \
        'conditions_from_params_excluded_columns explicitly. To retain unrestricted legacy filtering ' \
        'without this warning, set conditions_from_params_allowed_columns = nil and ' \
        'conditions_from_params_excluded_columns = []; this does not prevent inference of hidden values.'
      )
    end
  end
end
