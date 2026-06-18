class Milestone < ActiveRecord::Base
  belongs_to :project
  # section_id → categories: different FK name from Task#category_id, same target model.
  # Used to test shared tabs where two subforms tab by the same Category but via different columns.
  belongs_to :section, class_name: 'Category', foreign_key: :section_id
end