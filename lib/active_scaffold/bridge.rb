module ActiveScaffold
  class Bridge
    attr_accessor :name
    cattr_accessor :bridges
    cattr_accessor :bridges_run
    self.bridges = {}

    def self.register(file)
      match = file.match(/(active_scaffold\/bridges\/(.*))\.rb\Z/)
      self.bridges[match[2].to_sym] = match[1] if match
    end

    def self.load(bridge_name)
      bridge = self.bridges[bridge_name.to_sym]
      if bridge.is_a? String
        if ActiveScaffold.exclude_bridges.exclude? bridge_name.to_sym
          bridge = bridge.camelize.constantize
          self.bridges[bridge_name.to_sym] = bridge
        else
          self.bridges.delete bridge_name
          bridge = nil
        end
      end
      bridge
    end
    class << self
      alias_method :[], :load
    end
      
    def self.run_all
      return false if self.bridges_run
      self.bridges.keys.each{|bridge_name|
        bridge = self[bridge_name]
        bridge.run if bridge
      }
      self.bridges_run = true
    end
      
    def self.install
      raise(RunTimeError, "install not defined for bridge #{name}")
    end
      
    # by convention and default, use the bridge name as the required constant for installation
    def self.install?
      Object.const_defined? name.demodulize
    end
      
    def self.run
      install if install?
    end
  end
end

require File.join(File.dirname(__FILE__), 'bridges/shared/date_bridge.rb')
(Dir[File.join(File.dirname(__FILE__), "bridges/*.rb")] - [__FILE__]).each{|bridge_require|
  ActiveScaffold::Bridge.register bridge_require
} 
