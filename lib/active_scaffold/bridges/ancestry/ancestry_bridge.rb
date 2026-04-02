# frozen_string_literal: true

module ActiveScaffold::Bridges
  class Ancestry
    module AncestryBridge
      def initialize(model_id)
        super

        return unless model.respond_to? :ancestry_column

        columns << :parent_id
        columns[:parent_id].form_ui = :ancestry
        update.columns.exclude :ancestry
        create.columns.exclude :ancestry, :parent_id
        list.columns.exclude :ancestry, :parent_id
      end
    end

    module FormColumnHelpers
      def active_scaffold_input_ancestry(column, options, ui_options: column.options)
        record = options[:object]
        select_options = []
        select_control_options = {selected: record.parent_id}
        select_control_options[:include_blank] = as_(:_select_) if record.parent_id.nil?
        method = ui_options[:label_method] || :to_label
        traverse_ancestry = proc do |key, value|
          unless key == record
            select_options << ["#{'__' * key.depth}#{key.send(method)}", key.id]
            value.each(&traverse_ancestry) if value.is_a?(Hash) && !value.empty?
          end
        end
        record.class.arrange.each(&traverse_ancestry)
        select(:record, :ancestry, select_options, select_control_options, options)
      end
    end
  end
end

ActionView::Base.class_eval do
  include ActiveScaffold::Bridges::Ancestry::FormColumnHelpers
end
ActiveScaffold::Config::Core.prepend ActiveScaffold::Bridges::Ancestry::AncestryBridge
