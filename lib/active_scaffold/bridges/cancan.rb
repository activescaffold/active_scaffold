class ActiveScaffold::Bridges::Cancan < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), "cancan", "cancan_bridge.rb")

    ActiveScaffold::ClassMethods.send :include, ActiveScaffold::CancanBridge::ClassMethods
    ActiveScaffold::Actions::Core.send :include, ActiveScaffold::CancanBridge::Actions::Core
    ActiveScaffold::Actions::Nested.send :include, ActiveScaffold::CancanBridge::Actions::Core
    ActionController::Base.send :include, ActiveScaffold::CancanBridge::ModelUserAccess::Controller
    ActiveRecord::Base.send :include, ActiveScaffold::CancanBridge::ModelUserAccess::Model
    ActiveRecord::Base.send :include, ActiveScaffold::CancanBridge::ActiveRecord
  end
  def self.install?
    Object.const_defined? 'CanCan'
  end
end
