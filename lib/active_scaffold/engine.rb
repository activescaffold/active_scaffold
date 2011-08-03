module ActiveScaffold
  #do not use module Rails... cause Rails.logger will fail
  # not sure if it is a must though...
  #module Rails
    class Engine < ::Rails::Engine
    end
  #end
end
