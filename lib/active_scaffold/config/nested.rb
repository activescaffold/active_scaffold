module ActiveScaffold::Config
  class Nested < Base
    self.crud_type = :read

    def initialize(core_config)
      super
      @label = :add_existing_model
      @shallow_delete = self.class.shallow_delete
      @ignore_order_from_association = self.class.ignore_order_from_association
    end

    # global level configuration
    # --------------------------
    cattr_accessor :shallow_delete
    @@shallow_delete = true

    cattr_accessor :ignore_order_from_association

    # instance-level configuration
    # ----------------------------
    attr_accessor :shallow_delete

    attr_accessor :ignore_order_from_association

    # Add a nested ActionLink
    def add_link(attribute, options = {})
      column = @core.columns[attribute.to_sym]
      if column && column.association
        label =
          if column.polymorphic_association?
            column.label
          else
            column.association.klass.model_name.human(:count => column.singular_association? ? 1 : 2, :default => column.association.klass.name.pluralize)
          end
        options.reverse_merge! :security_method => :nested_authorized?, :label => label
        action_group = options.delete(:action_group) || self.action_group
        action_link = @core.link_for_association(column, options)
        @core.action_links.add_to_group(action_link, action_group) unless action_link.nil?
        action_link
      elsif column.nil?
        raise ArgumentError, "unknown column #{attribute}"
      elsif column.association.nil?
        raise ArgumentError, "column #{attribute} is not an association"
      end
    end

    def add_scoped_link(named_scope, options = {})
      action_link = @core.link_for_association_as_scope(named_scope.to_sym, options)
      @core.action_links.add_to_group(action_link, action_group) unless action_link.nil?
    end

    # the label for this Nested action. used for the header.
    attr_writer :label
  end
end
