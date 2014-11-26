class Building < ActiveRecord::Base
  belongs_to :owner, :class_name => 'Person', :counter_cache => true
  has_many :floors, :dependent => :delete_all

  has_one :address, :as => :addressable

  has_many :tenants, :through => :floors, :class_name => 'Person'

  if Rails.version < '4.0'
    after_update :update_buildings_count, :if => :owner_id_changed?
    
    def update_buildings_count
      Person.decrement_counter(:buildings_count, owner_id_was) if owner_id_was
      Person.increment_counter(:buildings_count, owner_id) if owner_id
    end
  end
end
