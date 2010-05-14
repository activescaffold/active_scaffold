module ActiveScaffold
  module Helpers
    module ViewHelpers
      def active_scaffold_stylesheets_with_date_picker(frontend = :default)
        active_scaffold_stylesheets_without_date_picker(frontend) + unobtrusive_datepicker_stylesheets
      end
      alias_method_chain :active_scaffold_stylesheets, :date_picker

      def active_scaffold_javascripts_with_date_picker(frontend = :default)
        active_scaffold_javascripts_without_date_picker(frontend) + unobtrusive_datepicker_javascripts
      end
      alias_method_chain :active_scaffold_javascripts, :date_picker
    end
  end
end
