# Bugfix: Team.offset(1).limit(1) throws an error
ActiveRecord::Base.instance_eval do
  def offset(*args, &block) 
    scoped.__send__(:offset, *args, &block)
  rescue NoMethodError       
    if scoped.nil?           
      'depends on :allow_nil'
    else                     
      raise                  
    end                      
  end       
end
