require 'active_support/concern'

class ActiveScaffold::Bridges::RecordSelect
  module Helpers
    extend ActiveSupport::Concern
    included do
      include FormColumnHelpers
      include SearchColumnHelpers
    end

    module FormColumnHelpers
      # requires RecordSelect plugin to be installed and configured.
      def active_scaffold_input_record_select(column, options)
        record = options.delete(:object)
        if column.association&.singular?
          multiple = column.options.dig(:html_options, :multiple)
          html = active_scaffold_record_select(record, column, options, record.send(column.name), multiple)
          html << active_scaffold_new_record_subform(column, record, options) if column.options[:add_new]
          html
        elsif column.association&.collection?
          active_scaffold_record_select(record, column, options, record.send(column.name), true)
        else
          active_scaffold_record_select_autocomplete(record, column, options)
        end
      end

      def active_scaffold_record_select(record, column, options, value, multiple)
        unless column.association
          raise ArgumentError, "record_select can only work against associations (and #{column.name} is not). "\
          'A common mistake is to specify the foreign key field (like :user_id), instead of the association (:user).'
        end
        klass = column.association.klass(record)
        return content_tag :span, '', :class => options[:class] unless klass

        remote_controller = active_scaffold_controller_for(klass).controller_path

        # if the opposite association is a :belongs_to (in that case association in this class must be has_one or has_many)
        # then only show records that have not been associated yet
        if column.association.has_one? || column.association.has_many?
          params[column.association.foreign_key] = ''
        end

        record_select_options = active_scaffold_input_text_options(options).merge(
          :controller => remote_controller
        )
        record_select_options.merge!(column.options)

        html =
          if multiple
            record_multi_select_field(options[:name], value || [], record_select_options.except(:required))
          else
            record_select_field(options[:name], value || klass.new, record_select_options)
          end
        html = self.class.field_error_proc.call(html, self) if record.errors[column.name].any?
        html
      end

      def active_scaffold_record_select_autocomplete(record, column, options)
        record_select_options = active_scaffold_input_text_options(options).reverse_merge(
          :controller => active_scaffold_controller_for(record.class).controller_path
        ).merge(column.options)
        html = record_select_autocomplete(options[:name], record, record_select_options)
        html = self.class.field_error_proc.call(html, self) if record.errors[column.name].any?
        html
      end
    end

    module SearchColumnHelpers
      def active_scaffold_search_record_select(column, options)
        value = field_search_record_select_value(column, options[:value])
        active_scaffold_record_select(options[:object], column, options, value, column.options[:multiple])
      end

      def field_search_record_select_value(column, value)
        return if value.blank?
        if column.options[:multiple]
          column.association.klass.find value.collect!(&:to_i)
        else
          column.association.klass.find(value.to_i)
        end
      rescue StandardError => e
        logger.error "#{e.class.name}: #{e.message} -- Sorry, we are not that smart yet. Attempted to restore search values to search fields :#{column.name} in #{controller.class}"
        raise e
      end
    end
  end
end

ActionView::Base.class_eval { include ActiveScaffold::Bridges::RecordSelect::Helpers }
