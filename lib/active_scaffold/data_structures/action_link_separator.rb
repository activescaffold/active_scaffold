# frozen_string_literal: true

module ActiveScaffold::DataStructures
  class ActionLinkSeparator
    def initialize(weight)
      @weight = weight
    end

    attr_reader :weight

    def ==(other)
      other == :separator
    end

    def name_to_cache; end # :nodoc:
  end
end
