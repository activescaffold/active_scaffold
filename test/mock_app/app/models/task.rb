class Task < ActiveRecord::Base
  belongs_to :project, optional: true
  belongs_to :category, optional: true

  PRIORITIES = [['Low', 'low'], ['Medium', 'medium'], ['High', 'high']].freeze
end
