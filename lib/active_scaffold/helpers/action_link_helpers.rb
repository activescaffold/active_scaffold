# frozen_string_literal: true

require 'active_scaffold/helpers/action_link_helpers/rendering'
require 'active_scaffold/helpers/action_link_helpers/column_links'
require 'active_scaffold/helpers/action_link_helpers/urls'
require 'active_scaffold/helpers/action_link_helpers/presentation'

module ActiveScaffold
  module Helpers
    # Helpers rendering action links
    module ActionLinkHelpers
      # params which mustn't be copying to nested links
      NESTED_PARAMS = %i[eid embedded association parent_scaffold].freeze

      def optional_cache_helper(method, key, cache, ...)
        if cache
          ActiveScaffold::Registry.cache(method, key) { send(method, ...) }
        else
          send(method, ...)
        end
      end

      include Rendering
      include ColumnLinks
      include Urls
      include Presentation
    end
  end
end
