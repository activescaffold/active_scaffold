class ActiveScaffold::Bridges::Chosen
  module Helpers
    def self.included(base)
      base.class_eval do
        include FormColumnHelpers
        include SearchColumnHelpers
      end
    end

    module FormColumnHelpers
      # requires RecordSelect plugin to be installed and configured.
      def active_scaffold_input_chosen(column, html_options)
        html_options[:class] << ' chosen'
        if column.plural_association?
          associated_options, select_options = active_scaffold_plural_association_options(column)
          options = {:selected => associated_options.collect(&:id), :include_blank => as_(:_select_)}

          html_options.update(:multiple => true).update(column.options[:html_options] || {})
          options.update(column.options)
          html_options[:name] = "#{html_options[:name]}[]" if html_options[:multiple] == true && !html_options[:name].to_s.ends_with?('[]')

          if (optgroup = options.delete(:optgroup))
            select(:record, column.name, active_scaffold_grouped_options(column, select_options, optgroup), options, html_options)
          else
            collection_select(:record, column.name, select_options, :id, column.options[:label_method] || :to_label, options, html_options)
          end
        else
          active_scaffold_input_select(column, html_options)
        end
      end
    end

    module SearchColumnHelpers
      def active_scaffold_search_chosen(column, options)
        options[:class] << ' chosen'
        active_scaffold_search_select(column, options)
      end

      def active_scaffold_search_multi_chosen(column, options)
        options[:class] << ' chosen'
        options[:multiple] = true
        active_scaffold_search_select(column, options)
      end
    end
  end
end

ActionView::Base.class_eval { include ActiveScaffold::Bridges::Chosen::Helpers }
