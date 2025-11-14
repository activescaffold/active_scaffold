# frozen_string_literal: true

# wrap the action rendering for ActiveScaffold controllers
module ActiveScaffold
  module ActionController # :nodoc:
    def render(*args, &)
      if self.class.uses_active_scaffold? && params[:adapter] && @rendering_adapter.nil? && request.xhr?
        @rendering_adapter = true # recursion control
        # if we need an adapter, then we render the actual stuff to a string and insert it into the adapter template
        opts = args.any? ? args.first : {}

        render partial: params[:adapter][1..],
               locals: {payload: render_to_string(opts.merge(layout: false), &).html_safe}, # rubocop:disable Rails/OutputSafety
               use_full_path: true, layout: false, content_type: :html
        @rendering_adapter = nil # recursion control
      else
        super
      end
    end
  end
end

module ActionController
  class Base
    prepend ActiveScaffold::ActionController
  end
end
