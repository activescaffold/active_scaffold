module ActiveScaffold::Config
  class Nested < Base
    def initialize(core_config)
      @core = core_config

      # inherit from the core's list of columns, but exclude a few extra fields by default
      self.columns = @core.columns.collect{|c| c.name}
    end

	# global level configuration
    # --------------------------
    
	# instance-level configuration
    # ----------------------------

    # Add a nested ActionLink
    def add_link(label, models)
      @core.action_links.add('nested', :label => label, :type => :record, :security_method => :nested_authorized?, :position => :after, :parameters => {:associations => models.join(' ')})
    end

    # the ActionLink for this action
    attr_accessor :link

    # the label for this Form action. used for the header.
    attr_accessor :label
    def label
      @label || "#{_('CREATE_FROM_EXISTING')} #{@core.label.singularize}"
    end

#TODO 2007-03-15 (EJM) Level=0 - Does nested need columns?
    # provides access to the list of columns specifically meant for the Form to use
    attr_reader :columns
    def columns=(val)
      @columns = ActiveScaffold::DataStructures::ActionColumns.new(*val)
    end
    
  end
end
