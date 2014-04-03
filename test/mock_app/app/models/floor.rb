class Floor < ActiveRecord::Base
  belongs_to :building
  belongs_to :tenant, :class_name => 'Person'
  has_one :address, :through => :building

  attr_accessor :number_required
  validates :number, :presence => true, :if => :number_required
end
