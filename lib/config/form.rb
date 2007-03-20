module ActiveScaffold::Config
  class Form < Base
    def initialize(core_config)
      @core = core_config

      # start with the ActionLink defined globally
      @link = self.class.link.clone

      # inherit from the core's list of columns, but exclude a few extra fields by default
      self.columns = @core.columns.collect{|c| c.name}
      self.columns.exclude :created_on, :created_at, :updated_on, :updated_at

      # no global setting here because multipart should only be set for specific forms
      @multipart = false
    end

    # global level configuration
    # --------------------------

    # instance-level configuration
    # ----------------------------

    # the ActionLink for this action
    attr_accessor :link

    # the label for this Form action. used for the header.
    attr_accessor :label

    # provides access to the list of columns specifically meant for the Form to use
    attr_reader :columns
    def columns=(val)
      @columns = ActiveScaffold::DataStructures::ActionColumns.new(*val)
    end

    # whether the form should be multipart
    attr_writer :multipart
    def multipart?
      @multipart ? true : false
    end
  end
end