# frozen_string_literal: true

require 'test_helper'

class CommonSearchTest < ActiveSupport::TestCase
  class CommonSearchControllerStub
    include ActiveScaffold::Actions::CommonSearch::InstanceMethods

    attr_reader :active_scaffold_outer_joins

    def initialize
      @active_scaffold_outer_joins = []
    end
  end

  def test_set_outer_joins_for_search_ignores_columns_without_search_joins
    plain_column = ActiveScaffold::DataStructures::Column.new(:a, ModelStub)
    joined_column = ActiveScaffold::DataStructures::Column.new(:b, ModelStub)
    joined_column.search_joins = :other_models
    controller = CommonSearchControllerStub.new

    controller.send(:set_outer_joins_for_search, [plain_column, joined_column])

    assert_equal [:other_models], controller.active_scaffold_outer_joins
  end
end
