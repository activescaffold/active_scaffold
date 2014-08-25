class Person < ActiveRecord::Base
  has_many :buildings, :foreign_key => :owner_id
  has_one :floor, :foreign_key => :tenant_id
  has_one :address, :through => :floor
  has_one :home, :through => :floor, :source => :building, :class_name => 'Building'

  has_many :contacts, :as => :contactable
  has_one :car, :dependent => :destroy
  
  has_many :files, :dependent => :destroy, :class_name => 'FileModel'
end
