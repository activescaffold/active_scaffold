ActiveScaffold::Config::Core.class_eval do
  def initialize_with_ancestry(model_id)
    initialize_without_ancestry(model_id)

    return unless self.model.respond_to? :ancestry_column

    col_config = self.columns[self.model.ancestry_column]
    unless col_config.nil?
      col_config.form_ui = :ancestry
      create.columns.exclude :ancestry
      list.columns.exclude :ancestry
    end
  end

  alias_method_chain :initialize, :ancestry
end

module ActiveScaffold
  module AncestryBridge
    module FormColumnHelpers
      def active_scaffold_input_ancestry(column, options)
        select_options = []
        traverse_ancestry = proc do|key, value|
          unless key == @record
            select_options << ["#{'__' * key.depth}#{key.to_label}", key.id]
            value.each(&traverse_ancestry) if value.is_a?(Hash) && !value.empty?
          end
        end
        @record.class.arrange.each(&traverse_ancestry)
        select(:record, :ancestry, select_options, { :selected => @record.send(:ancestry) }, options)
      end
    end
  end
end

ActionView::Base.class_eval do
  include ActiveScaffold::AncestryBridge::FormColumnHelpers
end
