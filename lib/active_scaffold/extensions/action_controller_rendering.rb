# wrap the action rendering for ActiveScaffold controllers
module ActionController #:nodoc:
  module WithActiveScaffold
    def render(*args, &block)
      if self.class.uses_active_scaffold? && params[:adapter] && @rendering_adapter.nil? && request.xhr?
        @rendering_adapter = true # recursion control
        # if we need an adapter, then we render the actual stuff to a string and insert it into the adapter template
        opts = args.blank? ? {} : args.first
        render :partial => params[:adapter][1..-1],
               :locals => {:payload => render_to_string(opts.merge(:layout => false), &block).html_safe},
               :use_full_path => true, :layout => false, :content_type => :html
        @rendering_adapter = nil # recursion control
      else
        super(*args, &block)
      end
    end
  end

  class Base
    prepend WithActiveScaffold
  end
end
