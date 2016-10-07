class ActiveScaffold::Bridges::Cancan < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'cancan', 'cancan_bridge.rb')

    ActiveScaffold::Core::ClassMethods.send :prepend, ActiveScaffold::Bridges::Cancan::ClassMethods
    ActiveScaffold::Actions::Core.send :prepend, ActiveScaffold::Bridges::Cancan::Actions::Core
    ActiveScaffold::Actions::Nested.send :prepend, ActiveScaffold::Bridges::Cancan::Actions::Core
    ActionController::Base.send :include, ActiveScaffold::Bridges::Cancan::ModelUserAccess::Controller
    ActionView::Base.send :include, ActiveScaffold::Bridges::Cancan::AssociationHelpers
    ::ActiveRecord::Base.send :include, ActiveScaffold::Bridges::Cancan::ModelUserAccess::Model
    ::ActiveRecord::Base.send :include, ActiveScaffold::Bridges::Cancan::ActiveRecord
  end

  def self.install?
    Object.const_defined? 'CanCan'
  end
end
