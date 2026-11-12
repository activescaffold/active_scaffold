# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class RespondsToParentTest < ActiveSupport::TestCase
  class Controller
    include ActiveScaffold::RespondsToParent

    attr_reader :rendered, :response

    def self.helpers
      ActionController::Base.helpers
    end

    def initialize
      @response = ActionDispatch::Response.new
    end

    def performed?
      true
    end

    def render(**options)
      @rendered = options
    end
  end

  def test_injects_response_script_into_parent_document_without_eval
    controller = Controller.new

    controller.responds_to_parent { controller.response.body = "window.updated = 'yes';" }

    html = controller.rendered[:html]
    assert_includes html, "var responseJavaScript = 'window.updated = \\'yes\\';';"
    assert_includes html, "parentDocument.querySelector('script[nonce]')"
    assert_includes html, 'if (nonceSource) script.nonce = nonceSource.nonce;'
    assert_includes html, 'parentDocument.head.appendChild(script);'
    assert_includes html, 'script.remove();'
    assert_not_includes html, 'eval('
    assert_equal 'text/html', controller.rendered[:content_type]
  end
end
