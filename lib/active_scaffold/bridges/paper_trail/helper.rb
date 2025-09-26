# frozen_string_literal: true

module ActiveScaffold::Bridges
  class PaperTrail
    module Helper
      def filter_action_links_for_deleted(action_links, record, options); end

      def display_action_links(action_links, record, options, &)
        if action_name == 'deleted'
          action_links = filter_action_links_for_deleted(action_links, record, options)
          return unless action_links
        end
        super
      end
    end
  end
end

ActionView::Base.class_eval do
  include ActiveScaffold::Bridges::PaperTrail::Helper
end
