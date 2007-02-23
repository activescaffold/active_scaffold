module ActiveScaffold
  def self.included(base)
    base.extend(ClassMethods)
    base.module_eval do
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
    def active_scaffold(model_id, &block)
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

    def uses_active_scaffold?
      !active_scaffold_config.nil?
    end
  end
end