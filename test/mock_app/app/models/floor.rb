class Floor < ActiveRecord::Base
  belongs_to :building, :counter_cache => true, :inverse_of => :floors, :optional => true
  belongs_to :tenant, :class_name => 'Person', :counter_cache => true, :inverse_of => :floor, :optional => true
  has_one :address, :through => :building

  attr_accessor :number_required
  validates :number, :presence => true, :if => :number_required
end
