class Building < ActiveRecord::Base
  belongs_to :owner, :class_name => 'Person'
  has_many :floors, :dependent => :delete_all

  has_one :address, :as => :addressable

  has_many :tenants, :through => :floors, :class_name => 'Person'
end
