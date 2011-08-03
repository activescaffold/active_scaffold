ActiveScaffold::Config::Core.class_eval do
  def initialize_with_ancestry(model_id)
    initialize_without_ancestry(model_id)

    return unless self.model.respond_to? :ancestry_column
    
    self.columns << :parent_id
    self.columns[:parent_id].form_ui = :ancestry
    update.columns.exclude :ancestry
    create.columns.exclude :ancestry, :parent_id
    list.columns.exclude :ancestry, :parent_id
  end

  alias_method_chain :initialize, :ancestry
end

module ActiveScaffold
  module AncestryBridge
    module FormColumnHelpers
      def active_scaffold_input_ancestry(column, options)
        select_options = []
        select_control_options = {:selected => @record.parent_id}
        select_control_options[:include_blank] = as_(:_select_) if @record.parent_id.nil?
        traverse_ancestry = proc do|key, value|
          unless key == @record
            select_options << ["#{'__' * key.depth}#{key.to_label}", key.id]
            value.each(&traverse_ancestry) if value.is_a?(Hash) && !value.empty?
          end
        end
        @record.class.arrange.each(&traverse_ancestry)
        select(:record, :ancestry, select_options, select_control_options, options)
      end
    end
  end
end

ActionView::Base.class_eval do
  include ActiveScaffold::AncestryBridge::FormColumnHelpers
end
