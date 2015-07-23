class ActiveScaffold::Bridges::RecordSelect
  module Helpers
    def self.included(base)
      base.class_eval do
        include FormColumnHelpers
        include SearchColumnHelpers
      end
    end

    module FormColumnHelpers
      # requires RecordSelect plugin to be installed and configured.
      def active_scaffold_input_record_select(column, options)
        record = options.delete(:object)
        ActiveSupport::Deprecation.warn 'Relying on @record is deprecated, include :object in html_options with record.', caller if record.nil? # TODO: Remove when relying on @record is removed
        record ||= @record # TODO: Remove when relying on @record is removed
        if column.singular_association?
          multiple = false
          multiple = column.options[:html_options][:multiple] if column.options[:html_options] &&  column.options[:html_options][:multiple]
          active_scaffold_record_select(record, column, options, record.send(column.name), multiple)
        elsif column.plural_association?
          active_scaffold_record_select(record, column, options, record.send(column.name), true)
        else
          active_scaffold_record_select_autocomplete(record, column, options)
        end
      end

      def active_scaffold_record_select(record, column, options, value, multiple)
        unless column.association
          raise ArgumentError, "record_select can only work against associations (and #{column.name} is not).  A common mistake is to specify the foreign key field (like :user_id), instead of the association (:user)."
        end
        klass =
          if column.polymorphic_association?
            record.send(column.association.foreign_type).constantize rescue nil
          else
            column.association.klass
          end
        return content_tag :span, '', :class => options[:class] unless klass

        remote_controller = active_scaffold_controller_for(klass).controller_path

        # if the opposite association is a :belongs_to (in that case association in this class must be has_one or has_many)
        # then only show records that have not been associated yet
        if [:has_one, :has_many].include?(column.association.macro)
          params.merge!(column.association.foreign_key => '')
        end

        record_select_options = active_scaffold_input_text_options(options).merge(
          :controller => remote_controller
        )
        record_select_options.merge!(column.options)

        html =
          if multiple
            record_multi_select_field(options[:name], value || [], record_select_options)
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
        value = field_search_record_select_value(column)
        active_scaffold_record_select(options[:object], column, options, value, column.options[:multiple])
      end

      def field_search_record_select_value(column)
        value = field_search_params[column.name]
        unless value.blank?
          if column.options[:multiple]
            column.association.klass.find value.collect!(&:to_i)
          else
            column.association.klass.find(value.to_i)
          end
        end
      rescue StandardError => e
        logger.error "#{e.class.name}: #{e.message} -- Sorry, we are not that smart yet. Attempted to restore search values to search fields :#{column.name} in #{controller.class}"
        raise e
      end
    end
  end
end

ActionView::Base.class_eval { include ActiveScaffold::Bridges::RecordSelect::Helpers }
