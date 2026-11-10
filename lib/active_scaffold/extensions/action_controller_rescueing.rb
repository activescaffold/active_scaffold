# frozen_string_literal: true

module ActiveScaffold
  module ActionControllerRescuing
    # Added to ActionController::Base so it can be overridden in ApplicationController.
    def deny_access
      head :forbidden # better for action or record not allowed, according to RFC 7231
    end
  end
end
