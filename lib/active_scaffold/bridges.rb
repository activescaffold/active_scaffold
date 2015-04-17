module ActiveScaffold
  module Bridges
    ActiveScaffold.autoload_subdir('bridges', self)
    module Shared
      autoload :DateBridge, 'active_scaffold/bridges/shared/date_bridge'
    end

    mattr_accessor :bridges
    mattr_accessor :bridges_run
    mattr_accessor :bridges_prepared
    self.bridges = {}

    def self.register(file)
      match = file.match(/(active_scaffold\/bridges\/(.*))\.rb\Z/)
      bridges[match[2].to_sym] = match[1] if match
    end

    def self.load(bridge_name)
      bridge = bridges[bridge_name.to_sym]
      if bridge.is_a? String
        if ActiveScaffold.exclude_bridges.exclude? bridge_name.to_sym
          bridge = bridge.camelize.constantize
          bridges[bridge_name.to_sym] = bridge
        else
          bridges.delete bridge_name
          bridge = nil
        end
      end
      bridge
    end
    class << self
      alias_method :[], :load
    end

    def self.run_all
      return false if bridges_run
      bridges.keys.each do |bridge_name|
        bridge = self[bridge_name]
        bridge.run if bridge
      end
      self.bridges_run = true
    end

    def self.prepare_all
      return false if bridges_prepared
      bridges.keys.each do |bridge_name|
        bridge = self[bridge_name]
        bridge.prepare if bridge && bridge.install?
      end
      self.bridges_prepared = true
    end

    def self.all_stylesheets
      bridges.keys.collect do |bridge_name|
        bridge = self[bridge_name]
        bridge.stylesheets if bridge && bridge.install?
      end.compact.flatten
    end

    def self.all_javascripts
      bridges.keys.collect do |bridge_name|
        bridge = self[bridge_name]
        bridge.javascripts if bridge && bridge.install?
      end.compact.flatten
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'bridges/*.rb')].each do |bridge|
  ActiveScaffold::Bridges.register bridge unless bridge == __FILE__
end
