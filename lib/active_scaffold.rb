unless Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR >= 0
  raise "This version of ActiveScaffold requires Rails 3.0 or higher.  Please use an earlier version."
end

begin
  require 'render_component'
rescue LoadError
end
begin
  require 'verification'
rescue LoadError
end

require 'active_scaffold_assets'
require 'active_scaffold/active_record_permissions'
require 'active_scaffold/paginator'
require 'active_scaffold/responds_to_parent'

require 'active_scaffold/version'

module ActiveScaffold
  autoload :AttributeParams, 'active_scaffold/attribute_params'
  autoload :Configurable, 'active_scaffold/configurable'
  autoload :Constraints, 'active_scaffold/constraints'
  autoload :Finder, 'active_scaffold/finder'
  autoload :MarkedModel, 'active_scaffold/marked_model'

  def self.autoload_subdir(dir, mod=self, root = File.dirname(__FILE__))
    Dir["#{root}/active_scaffold/#{dir}/*.rb"].each { |file|
      basename = File.basename(file, ".rb")
      mod.module_eval {
        autoload basename.camelcase.to_sym, "active_scaffold/#{dir}/#{basename}"
      }
    }
  end

  module Actions
    ActiveScaffold.autoload_subdir('actions', self)
  end

  module Bridges
    autoload :Bridge, 'active_scaffold/bridges/bridge'
  end

  module Config
    ActiveScaffold.autoload_subdir('config', self)
  end

  module DataStructures
    ActiveScaffold.autoload_subdir('data_structures', self)
  end

  module Helpers
    ActiveScaffold.autoload_subdir('helpers', self)
  end

  class ControllerNotFound < RuntimeError; end
  class DependencyFailure < RuntimeError; end
  class MalformedConstraint < RuntimeError; end
  class RecordNotAllowed < SecurityError; end
  class ActionNotAllowed < SecurityError; end
  class ReverseAssociationRequired < RuntimeError; end

  def self.included(base)
    base.extend(ClassMethods)
    base.module_eval do
      # TODO: these should be in actions/core
      before_filter :handle_user_settings
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

  def active_scaffold_session_storage(id = (params[:eid] || params[:controller]))
    session_index = "as:#{id}"
    session[session_index] ||= {}
    session[session_index]
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
  
  def self.js_framework=(framework)
    @@js_framework = framework
  end
  
  def self.js_framework
    @@js_framework ||= :prototype
  end

  def self.root
    File.dirname(__FILE__) + "/.."
  end

  module ClassMethods
    def active_scaffold(model_id = nil, &block)
      # initialize bridges here
      ActiveScaffold::Bridges::Bridge.run_all

      # converts Foo::BarController to 'bar' and FooBarsController to 'foo_bar' and AddressController to 'address'
      model_id = self.to_s.split('::').last.sub(/Controller$/, '').pluralize.singularize.underscore unless model_id

      # run the configuration
      @active_scaffold_config = ActiveScaffold::Config::Core.new(model_id)
      @active_scaffold_config_block = block
      self.links_for_associations

      @active_scaffold_overrides = []
      ActionController::Base.view_paths.each do |dir|
        active_scaffold_overrides_dir = File.join(dir.to_s,"active_scaffold_overrides")
        @active_scaffold_overrides << active_scaffold_overrides_dir if File.exists?(active_scaffold_overrides_dir)
      end
      @active_scaffold_overrides.uniq! # Fix rails duplicating some view_paths
      @active_scaffold_frontends = []
      if active_scaffold_config.frontend.to_sym != :default
        active_scaffold_custom_frontend_path = File.join(ActiveScaffold::Config::Core.plugin_directory, 'frontends', active_scaffold_config.frontend.to_s , 'views')
        @active_scaffold_frontends << active_scaffold_custom_frontend_path
      end
      active_scaffold_default_frontend_path = File.join(ActiveScaffold::Config::Core.plugin_directory, 'frontends', 'default' , 'views')
      @active_scaffold_frontends << active_scaffold_default_frontend_path
      @active_scaffold_custom_paths = []

      self.active_scaffold_superclasses_blocks.each {|superblock| self.active_scaffold_config.configure &superblock}
      self.active_scaffold_config.sti_children = nil # reset sti_children if set in parent block
      self.active_scaffold_config.configure &block if block_given?
      self.active_scaffold_config._configure_sti unless self.active_scaffold_config.sti_children.nil?
      self.active_scaffold_config._load_action_columns

      # defines the attribute read methods on the model, so record.send() doesn't find protected/private methods instead
      klass = self.active_scaffold_config.model
      klass.define_attribute_methods unless klass.attribute_methods_generated?
      # include the rest of the code into the controller: the action core and the included actions
      module_eval do
        include ActiveScaffold::Finder
        include ActiveScaffold::Constraints
        include ActiveScaffold::AttributeParams
        include ActiveScaffold::Actions::Core
        active_scaffold_config.actions.each do |mod|
          name = mod.to_s.camelize
          include "ActiveScaffold::Actions::#{name}".constantize

          # sneak the action links from the actions into the main set
          if link = active_scaffold_config.send(mod).link rescue nil
            if link.is_a? Array
              link.each {|current| active_scaffold_config.action_links.add_to_group(current, active_scaffold_config.send(mod).action_group)}
            elsif link.is_a? ActiveScaffold::DataStructures::ActionLink
              active_scaffold_config.action_links.add_to_group(link, active_scaffold_config.send(mod).action_group)
            end
          end
        end
      end
      active_scaffold_paths.each do |path|
        self.append_view_path(ActionView::ActiveScaffoldResolver.new(path))
      end
      self._add_sti_create_links if self.active_scaffold_config.add_sti_create_links?
    end

    # To be called after include action modules
    def _add_sti_create_links
      new_action_link = active_scaffold_config.action_links.collection['new']
      unless new_action_link.nil? || active_scaffold_config.sti_children.empty?
        active_scaffold_config.action_links.collection.delete('new')
        active_scaffold_config.sti_children.each do |child|
          new_sti_link = Marshal.load(Marshal.dump(new_action_link)) # deep clone
          new_sti_link.label = child.to_s.camelize.constantize.model_name.human
          new_sti_link.parameters = {:parent_sti => controller_path}
          new_sti_link.controller = Proc.new { active_scaffold_controller_for(child.to_s.camelize.constantize).controller_path }
          active_scaffold_config.action_links.collection.create.add(new_sti_link)
        end
      end
    end

    # Create the automatic column links. Note that this has to happen when configuration is *done*, because otherwise the Nested module could be disabled. Actually, it could still be disabled later, couldn't it?
    def links_for_associations
      return unless active_scaffold_config.actions.include? :list and active_scaffold_config.actions.include? :nested
      active_scaffold_config.columns.each do |column|
        next unless column.link.nil? and column.autolink?
        #lazy load of action_link, cause it was really slowing down app in dev mode
        #and might lead to trouble cause of cyclic constantization of controllers
        #and might be unnecessary cause it is done before columns are configured
        column.set_link(Proc.new {|col| link_for_association(col)})
      end
    end
    
    def link_for_association(column, options = {})
      begin
        controller = if column.polymorphic_association?
          :polymorph
        elsif options.include?(:controller)
          "#{options[:controller].to_s.camelize}Controller".constantize
        else
          active_scaffold_controller_for(column.association.klass)
        end
      rescue ActiveScaffold::ControllerNotFound
        controller = nil        
      end
      
      unless controller.nil?
        options.reverse_merge! :label => column.label, :position => :after, :type => :member, :controller => (controller == :polymorph ? controller : controller.controller_path), :column => column
        options[:parameters] ||= {}
        options[:parameters].reverse_merge! :parent_scaffold => controller_path, :association => column.association.name
        if column.plural_association?
          # note: we can't create nested scaffolds on :through associations because there's no reverse association.
          
          ActiveScaffold::DataStructures::ActionLink.new('index', options) #unless column.through_association?
        else
          actions = [:create, :update, :show] 
          actions = controller.active_scaffold_config.actions unless controller == :polymorph
          column.actions_for_association_links.delete :new unless actions.include? :create
          column.actions_for_association_links.delete :edit unless actions.include? :update
          column.actions_for_association_links.delete :show unless actions.include? :show
          ActiveScaffold::DataStructures::ActionLink.new(:none, options.merge({:crud_type => nil, :html_options => {:class => column.name}}))
        end 
      end
    end
    
    def link_for_association_as_scope(scope, options = {})
      options.reverse_merge! :label => scope, :position => :after, :type => :member, :controller => controller_path
      options[:parameters] ||= {}
      options[:parameters].reverse_merge! :parent_scaffold => controller_path, :named_scope => scope
      ActiveScaffold::DataStructures::ActionLink.new('index', options)
    end

    def add_active_scaffold_path(path)
      @active_scaffold_paths = nil # Force active_scaffold_paths to rebuild
      @active_scaffold_custom_paths << path
    end

    def add_active_scaffold_override_path(path)
      @active_scaffold_paths = nil # Force active_scaffold_paths to rebuild
      @active_scaffold_overrides.unshift path
    end

    def active_scaffold_paths
      return @active_scaffold_paths unless @active_scaffold_paths.nil?

      #@active_scaffold_paths = ActionView::PathSet.new
      @active_scaffold_paths = []
      @active_scaffold_paths.concat @active_scaffold_overrides unless @active_scaffold_overrides.nil?
      @active_scaffold_paths.concat @active_scaffold_custom_paths unless @active_scaffold_custom_paths.nil?
      @active_scaffold_paths.concat @active_scaffold_frontends unless @active_scaffold_frontends.nil?
      @active_scaffold_paths
    end

    def active_scaffold_config
      if @active_scaffold_config.nil?
        self.superclass.active_scaffold_config if self.superclass.respond_to? :active_scaffold_config
      else
        @active_scaffold_config
      end
    end

    def active_scaffold_config_block
      @active_scaffold_config_block
    end

    def active_scaffold_superclasses_blocks
      blocks = []
      klass = self.superclass
      while klass.respond_to? :active_scaffold_superclasses_blocks
        blocks << klass.active_scaffold_config_block
        klass = klass.superclass
      end
      blocks.compact.reverse
    end

    def active_scaffold_config_for(klass)
      begin
        controller = active_scaffold_controller_for(klass)
      rescue ActiveScaffold::ControllerNotFound
        config = ActiveScaffold::Config::Core.new(klass)
        config._load_action_columns
        config
      else
        controller.active_scaffold_config
      end
    end

    # Tries to find a controller for the given ActiveRecord model.
    # Searches in the namespace of the current controller for singular and plural versions of the conventional "#{model}Controller" syntax.
    # You may override this method to customize the search routine.
    def active_scaffold_controller_for(klass)
      controller_namespace = self.to_s.split('::')[0...-1].join('::') + '::'
      error_message = []
      [controller_namespace, ''].each do |namespace|
        ["#{klass.to_s.underscore.pluralize}", "#{klass.to_s.underscore.pluralize.singularize}"].each do |controller_name|
          begin
            controller = "#{namespace}#{controller_name.camelize}Controller".constantize
          rescue NameError => error
            # Only rescue NameError associated with the controller constant not existing - not other compile errors
            if error.message["uninitialized constant #{controller}"]
              error_message << "#{namespace}#{controller_name.camelize}Controller"
              next
            else
              raise
            end
          end
          raise ActiveScaffold::ControllerNotFound, "#{controller} missing ActiveScaffold", caller unless controller.uses_active_scaffold?
          raise ActiveScaffold::ControllerNotFound, "ActiveScaffold on #{controller} is not for #{klass} model.", caller unless controller.active_scaffold_config.model == klass
          return controller
        end
      end
      raise ActiveScaffold::ControllerNotFound, "Could not find " + error_message.join(" or "), caller
    end

    def uses_active_scaffold?
      !active_scaffold_config.nil?
    end
  end
end

require 'active_scaffold_env'

##
## Run the install assets script, too, just to make sure
## But at least rescue the action in production
##

Rails::Application.initializer("active_scaffold.install_assets") do
  begin
    ActiveScaffoldAssets.copy_to_public(ActiveScaffold.root, {:clean_up_destination => true})
  rescue
    raise $! unless Rails.env == 'production'
  end
end if defined?(ACTIVE_SCAFFOLD_GEM)

