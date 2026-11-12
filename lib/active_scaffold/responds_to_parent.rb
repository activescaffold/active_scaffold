# frozen_string_literal: true

module ActiveScaffold
  # Module containing the methods useful for child IFRAME to parent window communication
  module RespondsToParent
    # Executes the response body as JavaScript in the context of the parent window.
    # Use this method of you are posting a form to a hidden IFRAME or if you would like
    # to use IFRAME base RPC.
    def responds_to_parent(&)
      yield
      return unless performed?

      # Either pull out a redirect or the request body
      script =
        if response.has_header? 'location'
          "document.location.href = '#{self.class.helpers.escape_javascript response.delete_header('location').to_s}'"
        else
          response.body || ''
        end
      response.status = 200 if (300...400).cover? response.status

      # Inject the response into the parent document so it executes in the parent scope.
      # Reuse its CSP nonce when one is available, then replace the frame location so the
      # back button doesn't replay the action on targeted forms.
      script = responds_to_parent_html(script)

      # Clear out the previous render to prevent double render and then render
      if respond_to?(:erase_results, true)
        erase_results
      else
        instance_variable_set(:@_response_body, nil)
      end

      # We're returning HTML instead of JS now, content_type needed if not inside respond_to block
      render html: script.html_safe, content_type: 'text/html' # rubocop:disable Rails/OutputSafety
    end
    alias respond_to_parent responds_to_parent

    private

    def responds_to_parent_html(response_javascript)
      escaped_response = self.class.helpers.escape_javascript(response_javascript)
      "<html><body><script type='text/javascript' charset='utf-8'>
        var loc = document.location;
        var responseJavaScript = '#{escaped_response}';
        var parentDocument = window.parent.document;
        var script = parentDocument.createElement('script');
        var nonceSource = parentDocument.querySelector('script[nonce]');

        if (nonceSource) script.nonce = nonceSource.nonce;
        script.text = responseJavaScript;
        parentDocument.head.appendChild(script);
        script.remove();
        loc.replace('about:blank');
      </script></body></html>"
    end
  end
end
