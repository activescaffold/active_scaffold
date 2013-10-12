class Person < ActiveRecord::Base
  has_many :buildings, :foreign_key => :owner_id
  has_one :floor, :foreign_key => :tenant_id
  has_one :car
end
