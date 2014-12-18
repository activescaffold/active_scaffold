class Contact < ActiveRecord::Base
  belongs_to :contactable, :polymorphic => true, :counter_cache => true
end
