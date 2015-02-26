module ActiveScaffold::DataStructures
  class ActionLink
    # provides a quick way to set any property of the object from a hash
    def initialize(action, options = {})
      # set defaults
      self.action = action
      self.label = action
      self.confirm = false
      self.type = :collection
      self.inline = true
      self.method = :get
      self.crud_type = :delete if [:destroy].include?(action.try(:to_sym))
      self.crud_type = :create if [:create, :new].include?(action.try(:to_sym))
      self.crud_type = :update if [:edit, :update].include?(action.try(:to_sym))
      self.crud_type ||= :read
      self.column = nil
      self.image = nil
      self.dynamic_parameters = nil
      self.weight = 0

      # apply quick properties
      options.each_pair do |k, v|
        setter = "#{k}="
        send(setter, v) if self.respond_to? setter
      end
      self.toggle = self.action.try(:to_sym) == :index && (parameters.present? || dynamic_parameters) unless options.include? :toggle
    end

    def initialize_copy(action_link)
      self.parameters = parameters.clone if action_link.instance_variable_get(:@parameters)
      self.html_options = html_options.clone if action_link.instance_variable_get(:@html_options)
    end

    # the weight for this link in the action links collection, it will be used to sort the collection
    attr_accessor :weight

    # the action-path for this link. what page to request? this is required!
    attr_accessor :action

    # the controller for this action link. if nil, the current controller should be assumed.
    attr_writer :controller

    def controller
      @controller = @controller.call if @controller.is_a?(Proc)
      @controller
    end

    def static_controller?
      !(@controller.is_a?(Proc) || (@controller == :polymorph))
    end

    # a hash of request parameters
    attr_writer :parameters
    def parameters
      @parameters ||= {}
    end

    # if active class is added to link when current request matches link
    # enabled automatically for links to index with parameters or dynamic parameters
    # disable when is not needed so current request match check is skipped
    attr_accessor :toggle

    # a block for dynamic_parameters
    attr_accessor :dynamic_parameters

    # the RESTful method
    attr_accessor :method

    # what string to use to represent this action
    attr_writer :label
    def label
      @label.is_a?(Symbol) ? as_(@label) : @label
    end

    # image to use {:name => 'arrow.png', :size => '16x16'}
    attr_accessor :image

    # if the action requires confirmation
    def confirm=(value)
      @dhtml_confirm = nil if value
      @confirm = value
    end

    def confirm(label = '')
      @confirm.is_a?(String) ? @confirm : as_(@confirm, :label => label)
    end

    def confirm?
      @confirm.present?
    end

    # if the action uses a DHTML based (i.e. 2-phase) confirmation
    attr_accessor :dhtml_confirm
    def dhtml_confirm=(value)
      @confirm = nil if value
      @dhtml_confirm = value
    end

    def dhtml_confirm?
      @dhtml_confirm.present?
    end

    # what method to call on the controller to see if this action_link should be visible
    # if method return false, link will be disabled
    # note that this is only the UI part of the security. to prevent URL hax0rz, you also need security on requests (e.g. don't execute update method unless authorized).
    attr_writer :security_method
    def security_method
      @security_method || "#{action}_authorized?"
    end

    def security_method_set?
      @security_method.present?
    end

    # enable it to refresh the parent row when the view is closed
    attr_accessor :refresh_on_close

    # what method to call on the controller to see if this action_link should be visible
    # if method return true, link won't be displayed
    attr_accessor :ignore_method

    # the crud type of the (eventual?) action. different than :method, because this crud action may not be imminent.
    # this is used to determine record-level authorization (e.g. record.authorized_for?(:crud_type => link.crud_type).
    # options are :create, :read, :update, and :delete
    attr_accessor :crud_type

    # an "inline" link is inserted into the existing page
    # exclusive with popup? and page?
    def inline=(val)
      @inline = (val == true)
      self.popup = self.page = false if @inline
    end

    def inline?
      @inline
    end

    # a "popup" link displays in a separate (browser?) window. this will eventually take arguments.
    # exclusive with inline? and page?
    def popup=(val)
      @popup = (val == true)
      return unless @popup
      self.inline = self.page = false

      # the :method parameter doesn't mix with the :popup parameter
      # when/if we start using DHTML popups, we can bring :method back
      self.method = nil
    end

    def popup?
      @popup
    end

    # a "page" link displays by reloading the current page
    # exclusive with inline? and popup?
    def page=(val)
      @page = (val == true)
      self.inline = self.popup = false if @page
    end

    def page?
      @page
    end

    # where the result of this action should insert in the display.
    # for :type => :collection, supported values are:
    #   :top
    #   :bottom
    #   :replace (for updating the entire table)
    #   false (no attempt at positioning)
    # for :type => :member, supported values are:
    #   :before
    #   :replace
    #   :after
    #   false (no attempt at positioning)
    attr_writer :position
    def position
      return @position unless @position.nil? || @position == true
      return :replace if type == :member
      return :top if type == :collection
      raise "what should the default position be for #{type}?"
    end

    # what type of link this is. currently supported values are :collection and :member.
    attr_accessor :type

    # html options for the link
    attr_writer :html_options
    def html_options
      @html_options ||= {}
    end

    # nested action_links are referencing a column
    attr_accessor :column

    # don't close the panel when another action link is open
    attr_writer :keep_open
    def keep_open?
      @keep_open
    end

    # indicates that this a nested_link
    def nested_link?
      @column || (parameters && parameters[:named_scope])
    end

    def name_to_cache
      @name_to_cache ||= "#{controller || 'self'}_#{type}_#{action}#{'_' if parameters.present?}#{parameters.map { |k, v| "#{k}=#{v.is_a?(Array) ? v.join(',') : v}" }.join('_')}"
    end
  end
end
