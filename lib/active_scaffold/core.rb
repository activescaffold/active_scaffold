module ActiveScaffold
  module Core
    def self.included(base)
      base.extend(ClassMethods)
    end

    def setup_user_settings
      config = self.class.active_scaffold_config
      config.new_user_settings(user_settings_storage, params)
      return if ActiveScaffold.threadsafe
      config.actions.each do |action_name|
        conf_instance = config.send(action_name) rescue next # rubocop:disable Style/RescueModifier
        config.user.action_user_settings(conf_instance)
      end
    end

    def active_scaffold_config
      @active_scaffold_config ||= begin
        setup_user_settings unless self.class.active_scaffold_config.user
        if ActiveScaffold.threadsafe
          self.class.active_scaffold_config.user
        else
          self.class.active_scaffold_config
        end
      end
    end

    def active_scaffold_session_storage_key(id = nil)
      id ||= params[:eid] || "#{params[:controller]}#{"_#{nested_parent_id}" if nested?}"
      "as:#{id}"
    end

    def active_scaffold_session_storage(id = nil)
      session_index = active_scaffold_session_storage_key(id)
      session[session_index] ||= {}
      session[session_index]
    end

    def user_settings_storage
      if self.class.active_scaffold_config.store_user_settings
        active_scaffold_session_storage
      else
        {}
      end
    end

    module ClassMethods
      def active_scaffold(model_id = nil, &block)
        extend Prefixes
        # initialize bridges here
        ActiveScaffold::Bridges.run_all

        # converts Foo::BarController to 'bar' and FooBarsController to 'foo_bar' and AddressController to 'address'
        model_id ||= to_s.split('::').last.sub(/Controller$/, '').pluralize.singularize.underscore

        # run the configuration
        @active_scaffold_config = ActiveScaffold::Config::Core.new(model_id)
        @active_scaffold_config_block = block
        links_for_associations

        active_scaffold_superclasses_blocks.each { |superblock| active_scaffold_config.configure(&superblock) }
        active_scaffold_config.sti_children = nil # reset sti_children if set in parent block
        active_scaffold_config.configure(&block) if block_given?
        active_scaffold_config.class.after_config_callbacks.each do |callback|
          if callback.is_a?(Proc)
            callback.call
          elsif active_scaffold_config.respond_to?(callback)
            active_scaffold_config.send(callback)
          end
        end

        # defines the attribute read methods on the model, so record.send() doesn't find protected/private methods instead
        # define_attribute_methods is safe to call multiple times since rails 4.0.4
        active_scaffold_config.model.define_attribute_methods if active_scaffold_config.active_record?
        # include the rest of the code into the controller: the action core and the included actions
        module_eval do
          unless self < ActiveScaffold::Actions::Core
            include ActiveScaffold::Finder
            include ActiveScaffold::Constraints
            include ActiveScaffold::AttributeParams
            include ActiveScaffold::Actions::Core
          end
          active_scaffold_config.actions.each do |mod|
            include "ActiveScaffold::Actions::#{mod.to_s.camelize}".constantize
            mod_conf = active_scaffold_config.send(mod)
            active_scaffold_config._setup_action(mod) if ActiveScaffold.threadsafe
            next unless mod_conf.respond_to?(:link) && (link = mod_conf.link)

            # sneak the action links from the actions into the main set
            if link.is_a? Array
              link.each do |current_link|
                active_scaffold_config.action_links.add_to_group(current_link, active_scaffold_config.send(mod).action_group)
              end
            elsif link.is_a? ActiveScaffold::DataStructures::ActionLink
              active_scaffold_config.action_links.add_to_group(link, active_scaffold_config.send(mod).action_group)
            end
          end
        end
        _add_sti_create_links if active_scaffold_config.add_sti_create_links?
        return unless ActiveScaffold.threadsafe
        active_scaffold_config._cache_lazy_values
        active_scaffold_config.deep_freeze!
      end

      module Prefixes
        define_method 'local_prefixes' do
          @local_prefixes ||= begin
            prefixes = super()
            unless superclass.uses_active_scaffold? || prefixes.include?('active_scaffold_overrides')
              prefixes << 'active_scaffold_overrides'
            end
            prefixes
          end
        end
      end

      # To be called after include action modules
      def _add_sti_create_links
        new_action_link = active_scaffold_config.action_links.collection['new']
        return if new_action_link.nil? || active_scaffold_config.sti_children.empty?
        active_scaffold_config.action_links.collection.delete('new')
        active_scaffold_config.sti_children.each do |child|
          new_sti_link = Marshal.load(Marshal.dump(new_action_link)) # deep clone
          new_sti_link.label = as_(:create_model, :model => child.to_s.camelize.constantize.model_name.human)
          new_sti_link.parameters = {:parent_sti => controller_path}
          new_sti_link.controller = proc { active_scaffold_controller_for(child.to_s.camelize.constantize).controller_path }
          active_scaffold_config.action_links.collection.create.add(new_sti_link)
        end
      end

      # Create the automatic column links. Note that this has to happen when configuration is *done*,
      # because otherwise the Nested module could be disabled. Actually, it could still be disabled later, couldn't it?
      def links_for_associations
        return unless active_scaffold_config.actions.include?(:list) && active_scaffold_config.actions.include?(:nested)
        active_scaffold_config.columns.each do |column|
          next unless column.link.nil? && column.autolink?
          # lazy load of action_link, cause it was really slowing down app in dev mode
          # and might lead to trouble cause of cyclic constantization of controllers
          # and might be unnecessary cause it is done before columns are configured
          column.set_link(proc { |col| link_for_association(col) })
        end
      end

      def active_scaffold_controller_for_column(column, options = {})
        if column.association.polymorphic?
          :polymorph
        elsif options.include?(:controller)
          "#{options[:controller].to_s.camelize}Controller".constantize
        else
          active_scaffold_controller_for(column.association.klass)
        end
      rescue ActiveScaffold::ControllerNotFound
        nil
      end

      def link_for_association(column, options = {})
        return if (controller = active_scaffold_controller_for_column(column, options)).nil?
        options.reverse_merge! :position => :after, :type => :member, :column => column,
                               :controller => (controller == :polymorph ? controller : "/#{controller.controller_path}")
        options[:parameters] ||= {}
        options[:parameters].reverse_merge! :association => column.association.name
        if column.association.collection?
          ActiveScaffold::DataStructures::ActionLink.new('index', options.merge(:refresh_on_close => true))
        else
          actions = controller.active_scaffold_config.actions unless controller == :polymorph
          actions ||= %i[create update show]
          controller_actions = column.actions_for_association_links
          controller_actions = controller_actions.dup if controller_actions.frozen?
          controller_actions.delete :new unless actions.include? :create
          controller_actions.delete :edit unless actions.include? :update
          controller_actions.delete :show unless actions.include? :show
          options.merge!(html_options: {class: column.name}, controller_actions: Set.new(controller_actions))
          ActiveScaffold::DataStructures::ActionLink.new(nil, options)
        end
      end

      def link_for_association_as_scope(scope, options = {})
        options.reverse_merge! :label => scope, :position => :after, :type => :member, :controller => controller_path
        options[:parameters] ||= {}
        options[:parameters].reverse_merge! :named_scope => scope
        ActiveScaffold::DataStructures::ActionLink.new('index', options)
      end

      def add_active_scaffold_path(path)
        as_path = File.realpath File.join(ActiveScaffold::Config::Core.plugin_directory, 'app', 'views')
        index = view_paths.find_index { |p| p.to_s == as_path }
        if index
          self.view_paths = view_paths[0..index - 1] + Array(path) + view_paths[index..-1]
        else
          append_view_path path
        end
      end

      def active_scaffold_config
        if @active_scaffold_config.nil?
          superclass.active_scaffold_config if superclass.respond_to? :active_scaffold_config
        else
          @active_scaffold_config
        end
      end

      attr_reader :active_scaffold_config_block

      def active_scaffold_superclasses_blocks
        blocks = []
        klass = superclass
        while klass.respond_to? :active_scaffold_superclasses_blocks
          blocks << klass.active_scaffold_config_block
          klass = klass.superclass
        end
        blocks.compact.reverse
      end

      def active_scaffold_config_for(klass)
        active_scaffold_controller_for(klass).active_scaffold_config
      rescue ActiveScaffold::ControllerNotFound
        ActiveScaffold::Config::Core.new(klass)
      end

      def active_scaffold_controller_for(klass)
        return self if uses_active_scaffold? && klass == active_scaffold_config.model
        # noinspection RubyArgCount
        ActiveScaffold::Core.active_scaffold_controller_for(klass, to_s.deconstantize + '::')
      end

      def uses_active_scaffold?
        !active_scaffold_config.nil?
      end
    end

    # Tries to find a controller for the given ActiveRecord model.
    # Searches in the namespace of the current controller for singular and plural versions of the conventional "#{model}Controller" syntax.
    # You may override this method to customize the search routine.
    def self.active_scaffold_controller_for(klass, controller_namespace = '::')
      error_message = []
      class_names = [klass.to_s, klass.to_s.demodulize].map { |k| k.underscore.pluralize }.map { |k| [k, k.singularize] }.flatten
      [controller_namespace, ''].each do |namespace|
        class_names.each do |controller_name|
          begin
            controller = "#{namespace}#{controller_name.camelize}Controller".constantize
          rescue NameError => error
            # Only rescue NameError associated with the controller constant not existing - not other compile errors
            raise unless error.message["uninitialized constant #{controller}"]
            error_message << "#{namespace}#{controller_name.camelize}Controller"
            next
          end
          raise ActiveScaffold::ControllerNotFound, "#{controller} missing ActiveScaffold", caller unless controller.uses_active_scaffold?
          unless controller.active_scaffold_config.model.to_s == klass.to_s
            raise ActiveScaffold::ControllerNotFound, "ActiveScaffold on #{controller} is not for #{klass} model.", caller
          end
          return controller
        end
      end
      raise ActiveScaffold::ControllerNotFound, 'Could not find ' + error_message.join(' or '), caller
    end

    def self.column_type_cast(value, column)
      if defined?(ActiveRecord) && column.is_a?(ActiveRecord::ConnectionAdapters::Column)
        active_record_column_type_cast(value, column)
      elsif defined?(Mongoid) && column.is_a?(Mongoid::Fields::Standard)
        mongoid_column_type_cast(value, column)
      else
        value
      end
    end

    def self.mongoid_column_type_cast(value, column)
      return Time.zone.at(value.to_i) if value =~ /\A\d+\z/ && [Time, DateTime].include?(column.type)
      column.type.evolve value
    end

    def self.active_record_column_type_cast(value, column)
      return Time.zone.at(value.to_i) if value =~ /\A\d+\z/ && %i[time datetime].include?(column.type)
      cast_type = ActiveRecord::Type.lookup column.type
      cast_type ? cast_type.cast(value) : value
    end
  end
end
