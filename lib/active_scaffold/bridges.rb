module ActiveScaffold
  module Bridges
    ActiveScaffold.autoload_subdir('bridges', self)
    module Shared
      autoload :DateBridge, 'active_scaffold/bridges/shared/date_bridge'
    end

    mattr_accessor :bridges
    mattr_accessor :bridges_run
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
      self.bridges.keys.each do |bridge_name|
        bridge = self[bridge_name]
        bridge.run if bridge
      end
      self.bridges_run = true
    end

    def self.all_stylesheets
      self.bridges.keys.collect do |bridge_name|
        bridge = self[bridge_name]
        bridge.stylesheets if bridge and bridge.install?
      end.compact.flatten
    end

    def self.all_javascripts
      self.bridges.keys.collect do |bridge_name|
        bridge = self[bridge_name]
        bridge.javascripts if bridge and bridge.install?
      end.compact.flatten
    end
  end
end

(Dir[File.join(File.dirname(__FILE__), "bridges/*.rb")] - [__FILE__]).each{|bridge_require|
  ActiveScaffold::Bridges.register bridge_require
} 
