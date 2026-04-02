# frozen_string_literal: true

require 'test_helper'
require 'performance_test_help'

class ListCarsPerformanceTest < ActionDispatch::PerformanceTest
  self.profile_options =
    if ENV['BENCHMARK_TESTS']
      {metrics: [:wall_time]}
    else
      {metrics: %i[process_time], formats: %i[flat graph_html call_stack]}
    end
  def setup
    owners = Array.new(4) { |i| Person.create first_name: "Name#{i}" } << nil
    500.times { |i| Car.create(brand: 'Skoda', model: 'Fabia', person: owners[i % 5]) }
    CarsController.class_eval do
      before_action :setup

      def setup
        active_scaffold_config.list.pagination = false
      end
    end
  end

  def test_list
    get '/cars'
  end

  # def test_list2
  #   get '/cars?t=2'
  # end
  #
  # def test_list3
  #   get '/cars?t=3'
  # end
end
