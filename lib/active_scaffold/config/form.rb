module ActiveScaffold::Config
  class Form < Base
    def initialize(core_config)
      super
      # start with the ActionLink defined globally
      @link = self.class.link.clone unless self.class.link.nil?
      @action_group = self.class.action_group.clone if self.class.action_group
      @show_unauthorized_columns = self.class.show_unauthorized_columns

      # no global setting here because multipart should only be set for specific forms
      @multipart = false
    end

    # global level configuration
    # --------------------------
    # show value of unauthorized columns instead of skip them
    class_attribute :show_unauthorized_columns

    # instance-level configuration
    # ----------------------------

    # show value of unauthorized columns instead of skip them
    attr_accessor :show_unauthorized_columns
    
    # the ActionLink for this action
    attr_accessor :link

    # the label for this Form action. used for the header.
    attr_writer :label

    # provides access to the list of columns specifically meant for the Form to use
    def columns
      unless @columns # lazy evaluation
        self.columns = @core.columns._inheritable
        self.columns.exclude :created_on, :created_at, :updated_on, :updated_at, :marked
        self.columns.exclude *@core.columns.collect{|c| c.name if c.polymorphic_association?}.compact
      end
      @columns
    end
    
    public :columns=
    
    # whether the form should be multipart
    attr_writer :multipart
    def multipart?
      @multipart ? true : false
    end
  end
end
