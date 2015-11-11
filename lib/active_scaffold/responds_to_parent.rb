module ActiveScaffold
  # Module containing the methods useful for child IFRAME to parent window communication
  module RespondsToParent
    # Executes the response body as JavaScript in the context of the parent window.
    # Use this method of you are posting a form to a hidden IFRAME or if you would like
    # to use IFRAME base RPC.
    def responds_to_parent(&block)
      yield
      return unless performed?

      # Either pull out a redirect or the request body
      script =  if response.headers['Location']
                  "document.location.href = '#{self.class.helpers.escape_javascript response.headers.delete('Location').to_s}'"
                else
                  response.body || ''
                end
      response.status = 200 if (300...400).include? response.status

      # Eval in parent scope and replace document location of this frame
      # so back button doesn't replay action on targeted forms
      # loc = document.location to be set after parent is updated for IE
      # with(window.parent) - pull in variables from parent window
      # setTimeout - scope the execution in the windows parent for safari
      # window.eval - legal eval for Opera
      script = "<html><body><script type='text/javascript' charset='utf-8'>
        var loc = document.location;
        with(window.parent) { setTimeout(function() { window.eval('#{self.class.helpers.escape_javascript script}'); window.loc && loc.replace('about:blank'); }, 1) }
      </script></body></html>"

      # We're returning HTML instead of JS or XML now
      response.headers['Content-Type'] = 'text/html; charset=UTF-8'

      # Clear out the previous render to prevent double render and then render
      if respond_to?(:erase_results, true)
        erase_results
      else
        instance_variable_set(:@_response_body, nil)
      end

      render :text => script
    end
    alias_method :respond_to_parent, :responds_to_parent
  end
end
