require 'test_helper'
require 'performance_test_help'

class ListPerformanceTest < ActionDispatch::PerformanceTest
  self.profile_options = {metrics: [:process_time]}
  def setup
    500.times { Car.create(brand: 'Skoda', model: 'Fabia') }
    CarsController.class_eval do
      before_action :setup
      def list_columns
        active_scaffold_config.columns.select { |col| %i[brand model].include?(col.name) }
      end

      def setup
        active_scaffold_config.list.pagination = false
      end
    end
  end

  def test_list
    get '/cars'
  end
=begin
  def test_list2
    get '/cars?t=2'
  end

  def test_list3
    get '/cars?t=3'
  end
=end
end
