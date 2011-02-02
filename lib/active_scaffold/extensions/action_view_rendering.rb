module ActionView
  class LookupContext
    module ViewPaths
      def find_all_templates(name, prefix = nil, partial = false)
        templates = []
        @view_paths.each do |resolver|
          template = resolver.find_all(*args_for_lookup(name, prefix, partial)).first
          templates << template unless template.nil?
        end
        templates
      end
    end
  end
end

# wrap the action rendering for ActiveScaffold views
module ActionView::Rendering #:nodoc:
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
      options[:locals].reverse_merge!(@last_view[:locals] || {})
      if @last_view[:templates].nil?
        @last_view[:templates] = lookup_context.find_all_templates(@last_view[:view], controller_path, !@last_view[:is_template])
        @last_view[:templates].shift
      end
      options[:template] = @last_view[:templates].shift
      render_without_active_scaffold options
    elsif args.first.is_a?(Hash) and args.first[:active_scaffold]
      require 'digest/md5'
      options = args.first

      remote_controller = options[:active_scaffold]
      constraints = options[:constraints]
      conditions = options[:conditions]
      eid = Digest::MD5.hexdigest(params[:controller] + remote_controller.to_s + constraints.to_s + conditions.to_s)
      session["as:#{eid}"] = {:constraints => constraints, :conditions => conditions, :list => {:label => args.first[:label]}}
      options[:params] ||= {}
      options[:params].merge! :eid => eid, :embedded => true
      
      id = "as_#{eid}-content"
      url_options = {:controller => remote_controller.to_s, :action => 'index'}.merge(options[:params])
      
      if respond_to? :render_component
        render_component url_options
      else
        content_tag(:div, {:id => id}) do
          url = url_for(url_options)
          link_to(remote_controller.to_s, url, {:remote => true, :id => id}) <<
            if ActiveScaffold.js_framework == :prototype
            javascript_tag("new Ajax.Updater('#{id}', '#{url}', {method: 'get', evalScripts: true});")
          elsif ActiveScaffold.js_framework == :jquery
            javascript_tag("$('##{id}').load('#{url}');")
          end
        end
      end
      
    else
      options = args.first
      if options.is_a?(Hash)
        @last_view = {:view => options[:partial], :is_template => false} if options[:partial]
        @last_view = {:view => options[:template], :is_template => !!options[:template]} if @last_view.nil? && options[:template]
        @last_view[:locals] = options[:locals] if !@last_view.nil? && options[:locals]
      end
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
  
  # This is the template finder logic, keep it updated with however we find stuff in rails
  # currently this very similar to the logic in ActionBase::Base.render for options file
  # TODO: Work with rails core team to find a better way to check for this.
  def template_exists?(template_name, lookup_overrides = false)
    begin
      method = 'find_template'
      method << '_without_active_scaffold' unless lookup_overrides
      self.view_paths.send(method, template_name, @template_format)
      return true
    rescue ActionView::MissingTemplate => e
      return false
    end
  end
end
