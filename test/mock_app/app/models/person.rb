class Person < ActiveRecord::Base
  has_many :buildings, :foreign_key => :owner_id, :inverse_of => :owner
  has_one :floor, :foreign_key => :tenant_id, :inverse_of => :tenant
  has_one :address, :through => :floor
  has_one :home, :through => :floor, :source => :building, :class_name => 'Building'

  has_many :contacts, :as => :contactable
  has_one :car, :dependent => :destroy
  has_and_belongs_to_many :roles

  has_many :files, :dependent => :destroy, :class_name => 'FileModel'
end
