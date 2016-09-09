require 'active_scaffold/paginator'

Paginator.class_eval do
  module WithInfinite
    def number_of_pages
      super if @count
    end
  end

  # Total number of pages
  prepend WithInfinite

  # Is this an "infinite" paginator
  def infinite?
    @count.nil?
  end

  def count
    @count || first.items.size
  end
end

Paginator::Page.class_eval do
  module WithInfinite
    def next?
      return true if @pager.infinite?
      super
    end
  end

  # Checks to see if there's a page after this one
  prepend WithInfinite

  def empty?
    if @pager.infinite?
      items.to_a.empty?
    else
      @pager.count.zero?
    end
  end
end
