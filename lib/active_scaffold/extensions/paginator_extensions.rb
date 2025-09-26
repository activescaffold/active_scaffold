# frozen_string_literal: true

require 'active_scaffold/paginator'

module ActiveScaffold
  module Paginator
    # Total number of pages
    def number_of_pages
      super if @count
    end

    # Is this an "infinite" paginator
    def infinite?
      @count.nil?
    end

    def count
      @count || first.items.size
    end
  end

  module Page
    # Checks to see if there's a page after this one
    def next?
      @pager.infinite? || super
    end

    def empty?
      if @pager.infinite?
        items.to_a.empty?
      else
        @pager.count.zero?
      end
    end
  end
end

Paginator.class_eval { prepend ActiveScaffold::Paginator }
Paginator::Page.class_eval { prepend ActiveScaffold::Page }
