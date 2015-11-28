module ActiveScaffold::Config
  class Subform < Base
    def initialize(core_config)
      super
      @layout = self.class.layout # default layout
    end

    # global level configuration
    # --------------------------

    cattr_accessor :layout
    @@layout = :horizontal

    # instance-level configuration
    # ----------------------------

    attr_accessor :layout

    columns_accessor :columns, :copy => :update
  end
end
