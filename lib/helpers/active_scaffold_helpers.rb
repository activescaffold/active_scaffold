module ActionView::Helpers
  module ActiveScaffoldHelpers
    def active_scaffold_config_for(*args)
      @controller.class.active_scaffold_config_for(*args)
    end

    def active_scaffold_controller_for(*args)
      @controller.class.active_scaffold_controller_for(*args)
    end

    # easy way to include ActiveScaffold assets
    def active_scaffold_includes
      js = ActiveScaffold::Config::Core.javascripts.collect do |name|
        javascript_include_tag(ActiveScaffold::Config::Core.asset_path(:javascript, name))
      end.join('')

      css = stylesheet_link_tag(ActiveScaffold::Config::Core.asset_path(:stylesheet, "stylesheet.css"))
      ie_css = stylesheet_link_tag(ActiveScaffold::Config::Core.asset_path(:stylesheet, "stylesheet-ie.css"))

      js + "\n" + css + "\n<!--[if IE]>" + ie_css + "<![endif]-->\n"
    end

    # access to the configuration variable
    def active_scaffold_config
      @controller.class.active_scaffold_config
    end

    # a general-use loading indicator (the "stuff is happening, please wait" feedback)
    def loading_indicator_tag(options)
      image_tag "/images/active_scaffold/default/indicator.gif", :style => "visibility:hidden;", :id => loading_indicator_id(options), :alt => "loading indicator", :class => "loading-indicator"
    end

    def params_for(options = {})
      # :adapter and :position are one-use rendering arguments. they should not propagate.
      # :sort, :sort_direction, and :page are arguments that stored in the session. they need not propagate.
      # and wow. no we don't want to propagate :record.
      # :commit is a special rails variable for form buttons
      blacklist = [:adapter, :position, :sort, :sort_direction, :page, :record, :commit, :_method]
      unless @params_for
        @params_for = params.clone.delete_if { |key, value| blacklist.include? key.to_sym if key }
        @params_for[:controller] = '/' + @params_for[:controller] unless @params_for[:controller].first(1) == '/' # for namespaced controllers
        @params_for.delete(:id) if @params_for[:id].nil?
      end
      @params_for.merge(options)
    end

    # Provides a way to honor the :conditions on an association while searching the association's klass
    def association_options_find(association, conditions = nil)
      association.klass.find(:all, :conditions => controller.send(:merge_conditions, conditions, association.options[:conditions]))
    end

    def association_options_count(association, conditions = nil)
      association.klass.count(:all, :conditions => controller.send(:merge_conditions, conditions, association.options[:conditions]))
    end

    # Creates a javascript-based link that toggles the visibility of some element on the page.
    # By default, it toggles the visibility of the sibling after the one it's nested in. You may pass custom javascript logic in options[:of] to change that, though. For example, you could say :of => '$("my_div_id")'.
    # You may also flag whether the other element is visible by default or not, and the initial text will adjust accordingly.
    def link_to_visibility_toggle(options = {})
      options[:of] ||= '$(this.parentNode).next()'
      options[:default_visible] = true if options[:default_visible].nil?

      link_text = options[:default_visible] ? 'hide' : 'show'
      link_to_function as_(link_text), "e = #{options[:of]}; e.toggle(); this.innerHTML = (e.style.display == 'none') ? '#{as_('show')}' : '#{as_('hide')}'", :class => 'visibility-toggle'
    end
  end
end