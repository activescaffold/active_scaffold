class Floor < ActiveRecord::Base
  belongs_to :building, :counter_cache => true
  belongs_to :tenant, :class_name => 'Person', :counter_cache => true
  has_one :address, :through => :building

  attr_accessor :number_required
  validates :number, :presence => true, :if => :number_required

  if Rails.version < '4.0'
    after_update :update_floors_count, :if => :building_id_changed?

    def update_floors_count
      Building.decrement_counter(:floors_count, building_id_was) if building_id_was
      Building.increment_counter(:floors_count, building_id) if building_id
    end
  end
end
