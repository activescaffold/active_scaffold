require 'active_scaffold/paginator'

class Paginator
  # Total number of pages
  def number_of_pages_with_infinite
    number_of_pages_without_infinite if @count
  end
  alias_method_chain :number_of_pages, :infinite

  # Is this an "infinite" paginator
  def infinite?
    @count.nil?
  end

  def count
    @count || first.items.size
  end

  class Page
    # Checks to see if there's a page after this one
    def next_with_infinite?
      return true if @pager.infinite?
      next_without_infinite?
    end
    alias_method_chain :next?, :infinite

    def empty?
      if @pager.infinite?
        items.to_a.empty?
      else
        @pager.count == 0
      end
    end
  end
end
