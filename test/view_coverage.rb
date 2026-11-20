# frozen_string_literal: true

# Ruby resets line counters when ActionView compiles the same template path for
# another view class. Preserve the counters before each recompilation so ERB
# coverage does not depend on test-suite ordering.
module ViewCoverage
  class << self
    def capture(path)
      coverage = Coverage.peek_result[path]
      lines = coverage.is_a?(Hash) ? coverage[:lines] : coverage
      return unless lines

      @lines ||= {}
      @lines[path] = merge_lines(@lines[path], lines)
    end

    def merge(path, lines)
      merge_lines(@lines&.fetch(path, nil), lines)
    end

    private

    def merge_lines(previous, current)
      return current unless previous

      previous.zip(current).map do |old_count, new_count|
        next if old_count.nil? && new_count.nil?

        [old_count.to_i, new_count.to_i].max
      end
    end
  end

  module TemplateCompilation
    def compile!(...)
      ViewCoverage.capture(identifier) unless instance_variable_get(:@compiled)
      super
    end
  end

  module ResultAdapter
    private

    def adapt_one(file_name, cover_statistic)
      if cover_statistic.is_a?(Hash) && cover_statistic[:lines]
        cover_statistic[:lines] = ViewCoverage.merge(file_name, cover_statistic[:lines])
      end
      super
    end
  end
end

ActionView::Template.prepend(ViewCoverage::TemplateCompilation)
SimpleCov::ResultAdapter.prepend(ViewCoverage::ResultAdapter)
