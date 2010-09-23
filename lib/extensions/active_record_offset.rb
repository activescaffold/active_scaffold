# Bugfix: Team.offset(1).limit(1) throws an error
ActiveRecord::Base.instance_eval do
  delegate :offset, :to => :scoped  
end
