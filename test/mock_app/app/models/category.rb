class Category < ActiveRecord::Base
  has_many :tasks
  has_many :milestones, foreign_key: :section_id
end