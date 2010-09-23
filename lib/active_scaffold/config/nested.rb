module ActiveScaffold::Config
  class Nested < Base
    self.crud_type = :read

    def initialize(core_config)
      super
      @label = :add_existing_model
      self.shallow_delete = self.class.shallow_delete
    end

    # global level configuration
    # --------------------------
    cattr_accessor :shallow_delete
    @@shallow_delete = false

    # instance-level configuration
    # ----------------------------
    attr_accessor :shallow_delete

    # Add a nested ActionLink
    def add_link(label, association, options = {})
      if association.is_a? Array
        msg = "config.nested.add_link with multiple associations is not already supported. "
        if association.size == 1
          ::ActiveSupport::Deprecation.warn(msg + "Remove array", caller)
        else
          ::ActiveSupport::Deprecation.warn(msg + "The first model will be used", caller)
        end
        association = association.first
      end
      options.reverse_merge! :security_method => :nested_authorized?, :position => :after
      options.merge! :label => label, :type => :member, :parameters => {:associations => association}
      options[:html_options] ||= {}
      options[:html_options][:class] = [options[:html_options][:class], association].compact.join(' ')
      @core.action_links.add('nested', options)
    end

    # the label for this Nested action. used for the header.
    attr_writer :label
  end
end
