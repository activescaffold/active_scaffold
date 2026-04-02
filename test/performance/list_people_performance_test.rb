# frozen_string_literal: true

require 'test_helper'
require 'performance_test_help'

class ListPeoplePerformanceTest < ActionDispatch::PerformanceTest
  self.profile_options =
    if ENV['BENCHMARK_TESTS']
      {metrics: [:wall_time]}
    else
      {metrics: %i[process_time], formats: %i[flat graph_html call_stack]}
    end
  def setup
    200.times do |i|
      p = Person.create(first_name: "Name#{i}", last_name: 'Last')
      p.buildings = Array.new(4) { |j| Building.create name: "B#{j} of #{p.first_name}" } unless (i % 4).zero?
    end
    PeopleController.class_eval do
      before_action :setup
      def list_columns
        cols = %i[first_name last_name buildings]
        active_scaffold_config.columns.select { |col| cols.include?(col.name) }
      end

      def setup
        active_scaffold_config.list.pagination = false
      end
    end
  end

  def test_list
    get '/people'
  end
end
