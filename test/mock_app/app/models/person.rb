class Person < ActiveRecord::Base
  has_many :buildings, :foreign_key => :owner_id
  has_one :car
end
