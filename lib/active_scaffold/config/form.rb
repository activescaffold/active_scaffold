module ActiveScaffold::Config
  class Form < Base
    def initialize(core_config)
      super
      @show_unauthorized_columns = self.class.show_unauthorized_columns
      @refresh_list = self.class.refresh_list
      @persistent = self.class.persistent

      # no global setting here because multipart should only be set for specific forms
      @multipart = false
    end

    # global level configuration
    # --------------------------
    # show value of unauthorized columns instead of skip them
    class_attribute :show_unauthorized_columns

    # whether the form stays open after an update or not
    cattr_accessor :persistent
    @@persistent = false

    # whether we should refresh list after update or not
    cattr_accessor :refresh_list
    @@refresh_list = false

    # instance-level configuration
    # ----------------------------

    # show value of unauthorized columns instead of skip them
    attr_accessor :show_unauthorized_columns
    
    # the ActionLink for this action
    attr_accessor :link

    # the label for this Form action. used for the header.
    attr_writer :label

    # whether the form stays open after a create or not
    attr_accessor :persistent

    # whether we should refresh list after create or not
    attr_accessor :refresh_list

    # provides access to the list of columns specifically meant for the Form to use
    def columns
      unless @columns # lazy evaluation
        self.columns = @core.columns._inheritable
        self.columns.exclude :created_on, :created_at, :updated_on, :updated_at, :as_marked
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
