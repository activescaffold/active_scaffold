# wrap the action rendering for ActiveScaffold views
module ActionView #:nodoc:
  class Base
    # Adds two rendering options.
    #
    # ==render :super
    #
    # This syntax skips all template overrides and goes directly to the provided ActiveScaffold templates.
    # Useful if you want to wrap an existing template. Just call super!
    #
    # ==render :active_scaffold => #{controller.to_s}, options = {}+
    #
    # Lets you embed an ActiveScaffold by referencing the controller where it's configured.
    #
    # You may specify options[:constraints] for the embedded scaffold. These constraints have three effects:
    #   * the scaffold's only displays records matching the constraint
    #   * all new records created will be assigned the constrained values
    #   * constrained columns will be hidden (they're pretty boring at this point)
    #
    # You may also specify options[:conditions] for the embedded scaffold. These only do 1/3 of what
    # constraints do (they only limit search results). Any format accepted by ActiveRecord::Base.find is valid.
    #
    # Defining options[:label] lets you completely customize the list title for the embedded scaffold.
    #
    def render_with_active_scaffold(*args, &block)
      if args.first == :super
        options = args[1] || {}
        options[:locals] ||= {}

        known_extensions = [:erb, :rhtml, :rjs, :haml]
        # search through call stack for a template file (normally matches on first caller)
        # note that we can't use split(':').first because windoze boxen may have an extra colon to specify the drive letter. the
        # solution is to count colons from the *right* of the string, not the left. see issue #299.
        template_path = caller.find{|c| known_extensions.include?(c.split(':')[-3].split('.').last.to_sym) }
        template = File.basename(template_path).split('.').first
        active_scaffold_config.template_search_path.each do |active_scaffold_template_path|
          next if template_path.include? active_scaffold_template_path
          active_scaffold_template = File.join(active_scaffold_template_path, template)
          return render(:file => active_scaffold_template, :locals => options[:locals]) if @finder.file_exists? active_scaffold_template
        end
      elsif args.first.is_a?(Hash) and args.first[:active_scaffold]
        require 'digest/md5'
        options = args.first

        remote_controller = options[:active_scaffold]
        constraints = options[:constraints]
        conditions = options[:conditions]
        eid = Digest::MD5.hexdigest(params[:controller] + remote_controller.to_s + constraints.to_s + conditions.to_s)
        session["as:#{eid}"] = {:constraints => constraints, :conditions => conditions, :list => {:label => args.first[:label]}}
        options[:params] ||= {}
        options[:params].merge! :eid => eid

        render_component :controller => remote_controller.to_s, :action => 'table', :params => options[:params]
      else
        render_without_active_scaffold(*args, &block)
      end
    end
    alias_method_chain :render, :active_scaffold
    
    def partial_pieces(partial_path)
      if partial_path.include?('/')
        return File.dirname(partial_path), File.basename(partial_path)
      else
        return controller.class.controller_path, partial_path
      end
    end
  end
end

module ActionView #:nodoc:
  class PartialTemplate < Template #:nodoc:
    def initialize_with_active_scaffold(view, partial_path, object = nil, locals = {})
      if view.controller.class.respond_to?(:uses_active_scaffold?) and view.controller.class.uses_active_scaffold?
        partial_path = rewrite_partial_path_for_active_scaffold(view, partial_path)
      end
      initialize_without_active_scaffold(view, partial_path, object, locals)
    end
    alias_method_chain :initialize, :active_scaffold
    
    private
      def rewrite_partial_path_for_active_scaffold(view, partial_path)
        path, partial_name = partial_pieces(view, partial_path)

        # test for the actual file
        return partial_path if view.finder.file_exists? File.join(path, "_#{partial_name}")
      
        # check the ActiveScaffold-specific directories
        view.controller.active_scaffold_config.template_search_path.each do |template_path|
          return File.join(template_path, partial_name) if view.finder.file_exists? File.join(template_path, "_#{partial_name}")
        end
        return partial_path
      end
  end
end