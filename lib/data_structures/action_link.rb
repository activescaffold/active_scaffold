module ActiveScaffold::DataStructures
  class ActionLink
    # provides a quick way to set any property of the object from a hash
    def initialize(action, options = {})
      # set defaults
      self.action = action
      self.label = action
      self.confirm = false
      self.type = :table
      self.inline = true
      self.method = :get
      self.crud_type = :destroy if [:destroy].include?(action.to_sym)
      self.crud_type = :create if [:create, :new].include?(action.to_sym)
      self.crud_type = :update if [:edit, :update].include?(action.to_sym)
      self.crud_type ||= :read

      # apply quick properties
      options.each_pair do |k, v|
        setter = "#{k}="
        self.send(setter, v) if self.respond_to? setter
      end
    end

    # the action-path for this link. what page to request? this is required!
    attr_accessor :action

    # a hash of request parameters
    attr_accessor :parameters

    # the RESTful method
    attr_accessor :method

    # what string to use to represent this action
    attr_writer :label
    def label
      as_(@label)
    end

    # if the action requires confirmation
    attr_writer :confirm
    def confirm
      @confirm.is_a?(String) ? as_(@confirm) : @confirm
    end
    def confirm?
      @confirm ? true : false
    end

    # what method to call on the controller to see if this action_link should be visible
    # note that this is only the UI part of the security. to prevent URL hax0rz, you also need security on requests (e.g. don't execute update method unless authorized).
    attr_writer :security_method
    def security_method
      @security_method || "#{self.label.underscore.downcase.gsub(/ /, '_')}_authorized?"
    end

    # the crud type of the (eventual?) action. different than :method, because this crud action may not be imminent.
    # this is used to determine record-level authorization (e.g. record.authorized_for?(:action => link.crud_type).
    # options are :create, :read, :update, and :destroy
    attr_accessor :crud_type

    # an "inline" link is inserted into the existing page
    # exclusive with popup? and page?
    def inline=(val)
      @inline = (val == true)
      self.popup, self.page = false if @inline
    end
    def inline?; @inline end

    # a "popup" link displays in a separate (browser?) window. this will eventually take arguments.
    # exclusive with inline? and page?
    def popup=(val)
      @popup = (val == true)
      self.inline, self.page = false if @popup
    end
    def popup?; @popup end

    # a "page" link displays by reloading the current page
    # exclusive with inline? and popup?
    def page=(val)
      @page = (val == true)
      self.inline, self.popup = false if @page
    end
    def page?; @page end

    # where the result of this action should insert in the display.
    # for :type => :table, supported values are:
    #   :top
    #   :bottom
    #   :replace (for updating the entire table)
    #   false (no attempt at positioning)
    # for :type => :record, supported values are:
    #   :before
    #   :replace
    #   :after
    #   false (no attempt at positioning)
    attr_writer :position
    def position
      return @position unless @position.nil? or @position == true
      return :replace if self.type == :record
      return :top if self.type == :table
      raise "what should the default position be for #{self.type}?"
    end

    # what type of link this is. currently supported values are :table and :record.
    attr_accessor :type
  end
end