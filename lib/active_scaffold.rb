module ActiveScaffold
  def self.included(base)
    base.extend(ClassMethods)
    base.module_eval do
      # TODO: these should be in actions/core
      before_filter :handle_user_settings
      before_filter :handle_column_constraints
    end
  end

  def self.set_defaults(&block)
    ActiveScaffold::Config::Core.configure &block
  end

  def active_scaffold_config
    self.class.active_scaffold_config
  end

  def active_scaffold_config_for(klass)
    self.class.active_scaffold_config_for(klass)
  end

  def active_scaffold_session_storage
    id = params[:eid] || params[:controller]
    session_index = "as:#{id}"
    session[session_index] ||= {}
    session[session_index]
  end

  def active_scaffold_constraints
    return active_scaffold_session_storage[:constraints] || {}
  end

  # at some point we need to pass the session and params into config. we'll just take care of that before any particular action occurs by passing those hashes off to the UserSettings class of each action.
  def handle_user_settings
    if self.class.uses_active_scaffold?
      active_scaffold_config.actions.each do |action_name|
        conf_instance = active_scaffold_config.send(action_name) rescue next
        next if conf_instance.class::UserSettings == ActiveScaffold::Config::Base::UserSettings # if it hasn't been extended, skip it
        active_scaffold_session_storage[action_name] ||= {}
        conf_instance.user = conf_instance.class::UserSettings.new(conf_instance, active_scaffold_session_storage[action_name], params)
      end
    end
  end

  def handle_column_constraints
    if self.class.uses_active_scaffold?
      active_scaffold_config.actions.each do |action_name|
        action = active_scaffold_config.send(action_name)
        next unless action.respond_to? :columns
        action.columns.constraint_columns = active_scaffold_constraints.keys
      end
    end
  end

  class ColumnNotAllowed < SecurityError; end
  class RecordNotAllowed < SecurityError; end

  module ClassMethods
    def active_scaffold(model_id = nil, &block)
      # converts Foo::BarController to 'bar' and FooBarsController to 'foo_bar' and AddressController to 'address'
      model_id = self.to_s.split('::').last.sub(/Controller$/, '').pluralize.singularize.underscore unless model_id

      # run the configuration
      @active_scaffold_config = ActiveScaffold::Config::Core.new(model_id)
      self.active_scaffold_config.configure &block if block_given?
      self.active_scaffold_config._load_action_columns

      # include the rest of the code into the controller: the action core and the included actions
      module_eval do
        include ActiveScaffold::Finder
        include ActiveScaffold::Actions::Core
        active_scaffold_config.actions.each do |mod|
          name = mod.to_s.camelize
          include eval("ActiveScaffold::Actions::#{name}") if ActiveScaffold::Actions.const_defined? name

          # sneak the action links from the actions into the main set
          if link = active_scaffold_config.send(mod).link rescue nil
            active_scaffold_config.action_links << link
          end
        end
      end
    end

    def active_scaffold_config
       @active_scaffold_config || self.superclass.instance_variable_get('@active_scaffold_config')
    end

    ## TODO We should check the the model being used is the same Class
    ##      ie make sure ProductsController doesn't active_scaffold :shoe
    def active_scaffold_config_for(klass)
      controller, controller_path = active_scaffold_controller_for(klass)
      return controller.active_scaffold_config unless controller.nil? or !controller.uses_active_scaffold?
      config = ActiveScaffold::Config::Core.new(klass)
      config._load_action_columns
      config
    end

    # :parent_controller, pass in something like, params[:controller], this will resolve the controller to the proper path for subsequent call to render :active_scaffold or render :component.
    def active_scaffold_controller_for(klass, parent_controller = nil)
      controller_path = ""
      controller_named_path = ""
      if parent_controller and parent_controller.include?("/")
        path = parent_controller.split('/')
        path.pop # remove the parent controller
        controller_named_path = path.collect{|p| p.capitalize}.join("::") + "::"
        controller_path = path.join("/") + "/"
      end
      ["#{klass.to_s.underscore}", "#{klass.to_s.underscore.pluralize}", "#{klass.to_s.underscore.singularize}"].each do |controller_name|
        controller = "#{controller_named_path}#{controller_name.camelize}Controller".constantize rescue next
        return controller, "#{controller_path}#{controller_name}"
      end
      nil
    end

    def uses_active_scaffold?
      !active_scaffold_config.nil?
    end
  end
end