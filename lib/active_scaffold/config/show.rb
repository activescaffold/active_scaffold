module ActiveScaffold::Config
  class Show < Base
    self.crud_type = :read

    # global level configuration
    # --------------------------
    cattr_accessor :link
    @@link = ActiveScaffold::DataStructures::ActionLink.new('show', :label => :show, :type => :member, :security_method => :show_authorized?, :ignore_method => :show_ignore?)
    # instance-level configuration
    # ----------------------------

    # the ActionLink for this action
    attr_accessor :link
    # the label for this action. used for the header.
    attr_writer :label

    columns_accessor :columns
  end
end
