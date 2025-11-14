# frozen_string_literal: true

module ActiveScaffold::DataStructures
  class FilterOption < ActionLink
    attr_reader :name, :filter_name
    attr_writer :description
    attr_accessor :conditions

    def initialize(filter_name, name, options = {})
      @filter_name = filter_name
      @label = @name = name.to_sym
      super(
        :index,
        options.merge(
          action: :index,
          type: :collection,
          method: :get,
          position: false,
          toggle: true
        )
      )
      parameters.merge!(filter_name => name)
    end

    def description
      case @description
      when Symbol
        ActiveScaffold::Registry.cache(:translations, @description) { as_(@description) }
      else
        @description
      end
    end
  end
end
