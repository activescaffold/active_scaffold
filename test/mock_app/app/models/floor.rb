class Floor < ActiveRecord::Base
  belongs_to :building
  belongs_to :tenant, :class_name => 'Person'
  has_one :address, :through => :building
end
