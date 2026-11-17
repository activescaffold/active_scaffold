# frozen_string_literal: true

module ActiveScaffold
  module TestSupport
    module Javascript
      # The reusable application cannot depend on a host ApplicationController.
      class FixtureController < ::ActionController::Base # rubocop:disable Rails/ApplicationController
        helper ActiveScaffold::Helpers::AssetsHelpers

        def show
          render body: document(FixtureStore.fetch(params[:id])), content_type: 'text/html'
        rescue KeyError
          head :not_found
        end

        private

        def document(fixture)
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <meta charset="utf-8">
                <title>ActiveScaffold plugin JavaScript test</title>
                <link rel="icon" href="data:,">
                #{helpers.csrf_meta_tags}
                #{helpers.javascript_include_tag('jquery', 'jquery_ujs')}
                #{helpers.javascript_tag(error_capture, nonce: true)}
              </head>
              <body>
                <main id="active-scaffold-javascript-fixture">#{fixture}</main>
                #{helpers.active_scaffold_javascript_tag}
              </body>
            </html>
          HTML
        end

        def error_capture
          <<~JS
            window.activeScaffoldTestErrors = [];
            window.addEventListener('error', function(event) {
              window.activeScaffoldTestErrors.push(event.message || String(event.error));
            });
            window.addEventListener('unhandledrejection', function(event) {
              window.activeScaffoldTestErrors.push(String(event.reason));
            });
            jQuery(document).on('active-scaffold:loaded', function() {
              document.documentElement.dataset.activeScaffoldLoaded = 'true';
            });
          JS
        end
      end
    end
  end
end
