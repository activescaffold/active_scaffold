module ActiveScaffold
  module RecordSelectBridge
    def self.included(base)
      base.class_eval do
        include FormColumnHelpers
        include SearchColumnHelpers
        include ViewHelpers
      end
    end

    module ViewHelpers
      def self.included(base)
        base.alias_method_chain :active_scaffold_includes, :record_select
      end

      def active_scaffold_includes_with_record_select(*args)
        active_scaffold_includes_without_record_select(*args) + record_select_includes
      end
    end

    module FormColumnHelpers
      # requires RecordSelect plugin to be installed and configured.
      def active_scaffold_input_record_select(column, options)
        if column.singular_association?
          active_scaffold_record_select(column, options, @record.send(column.name), false)
        elsif column.plural_association?
          active_scaffold_record_select(column, options, @record.send(column.name), true)
        end
      end

      def active_scaffold_record_select(column, options, value, multiple)
        unless column.association
          raise ArgumentError, "record_select can only work against associations (and #{column.name} is not).  A common mistake is to specify the foreign key field (like :user_id), instead of the association (:user)."
        end
        remote_controller = active_scaffold_controller_for(column.association.klass).controller_path

        # if the opposite association is a :belongs_to (in that case association in this class must be has_one or has_many)
        # then only show records that have not been associated yet
        if [:has_one, :has_many].include?(column.association.macro)
          params.merge!({column.association.primary_key_name => ''})
        end
 
        record_select_options = {:controller => remote_controller, :id => options[:id]}
        record_select_options.merge!(options)
        record_select_options.merge!(active_scaffold_input_text_options)
        record_select_options.merge!(column.options)
        record_select_options[:onchange] = "function(id, label) { this.value = id; #{record_select_options[:onchange]} }" if record_select_options[:onchange]

        if multiple
          record_multi_select_field(options[:name], value || [], record_select_options)
        else
          record_select_field(options[:name], value || column.association.klass.new, record_select_options)
        end
      end
    end

    module SearchColumnHelpers
      def active_scaffold_search_record_select(column, options)
        begin
          value = field_search_params[column.name]
          value = unless value.blank?
            if column.options[:multiple]
              column.association.klass.find value.collect!(&:to_i)
            else
              column.association.klass.find(value.to_i)
            end
          end
        rescue Exception => e
          logger.error Time.now.to_s + "Sorry, we are not that smart yet. Attempted to restore search values to search fields but instead got -- #{e.inspect} -- on the ActiveScaffold column = :#{column.name} in #{@controller.class}"
          raise e
        end

        active_scaffold_record_select(column, options, value, column.options[:multiple])
      end
    end
  end
end

ActionView::Base.class_eval { include ActiveScaffold::RecordSelectBridge }
