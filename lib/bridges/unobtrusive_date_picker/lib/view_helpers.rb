module ActiveScaffold
  module UnobtrusiveDatePickerHelpers
    def self.included(base)
      base.alias_method_chain :active_scaffold_stylesheets, :date_picker
      base.alias_method_chain :active_scaffold_javascripts, :date_picker
    end

    def active_scaffold_stylesheets_with_date_picker(frontend = :default)
      active_scaffold_stylesheets_without_date_picker(frontend) + unobtrusive_datepicker_stylesheets
    end

    def active_scaffold_javascripts_with_date_picker(frontend = :default)
      active_scaffold_javascripts_without_date_picker(frontend) + unobtrusive_datepicker_javascripts
    end
  end
end
