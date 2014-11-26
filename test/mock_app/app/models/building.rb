class Building < ActiveRecord::Base
  belongs_to :owner, :class_name => 'Person', :counter_cache => true, :inverse_of => :building
  has_many :floors, :dependent => :destroy, :inverse_of => :building

  has_one :address, :as => :addressable

  has_many :tenants, :through => :floors, :class_name => 'Person'
end
