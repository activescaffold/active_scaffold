class Task < ActiveRecord::Base
  belongs_to :project
  belongs_to :category

  PRIORITIES = [['Low', 'low'], ['Medium', 'medium'], ['High', 'high']].freeze
end