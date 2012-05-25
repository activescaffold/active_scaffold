module ActiveScaffold::Config
  class Nested < Base
    self.crud_type = :read

    def initialize(core_config)
      super
      @label = :add_existing_model
      @shallow_delete = self.class.shallow_delete
    end

    # global level configuration
    # --------------------------
    cattr_accessor :shallow_delete
    @@shallow_delete = true

    # instance-level configuration
    # ----------------------------
    attr_accessor :shallow_delete

    # Add a nested ActionLink
    def add_link(attribute, options = {})
      column = @core.columns[attribute.to_sym]
      unless column.nil? || column.association.nil?
        options.reverse_merge! :security_method => :nested_authorized?, :label => column.association.klass.model_name.human({:count => 2, :default => column.association.klass.name.pluralize}) 
        action_link = @core.link_for_association(column, options)
        action_link.action ||= :index
        @core.action_links.add_to_group(action_link, action_group) unless action_link.nil?
      else
        
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
