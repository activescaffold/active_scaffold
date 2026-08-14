class Car < ActiveRecord::Base
  belongs_to :person, optional: true
end
