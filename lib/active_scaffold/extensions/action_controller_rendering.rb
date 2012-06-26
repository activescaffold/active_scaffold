# wrap the action rendering for ActiveScaffold controllers
module ActionController #:nodoc:
  class Base
    def render_with_active_scaffold(*args, &block)
      if self.class.uses_active_scaffold? and params[:adapter] and @rendering_adapter.nil? and request.xhr?
        @rendering_adapter = true # recursion control
        # if we need an adapter, then we render the actual stuff to a string and insert it into the adapter template
        opts = args.blank? ? Hash.new : args.first
        render :partial => params[:adapter][1..-1],
        :locals => {:payload => render_to_string(opts.merge(:layout => false), &block).html_safe},
               :use_full_path => true, :layout => false, :content_type => :html
        @rendering_adapter = nil # recursion control
      else
        render_without_active_scaffold(*args, &block)
      end
    end
    alias_method_chain :render, :active_scaffold
  end
end

