# frozen_string_literal: true

class ActiveScaffold::Bridges::Cancan < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'cancan', 'cancan_bridge.rb')

    ActiveScaffold::Core::ClassMethods.prepend ActiveScaffold::Bridges::Cancan::ClassMethods
    ActiveScaffold::Actions::Core.prepend ActiveScaffold::Bridges::Cancan::Actions::Core
    ActiveScaffold::Actions::Nested.prepend ActiveScaffold::Bridges::Cancan::Actions::Core
    ActiveSupport.on_load(:action_controller) { include ActiveScaffold::Bridges::Cancan::ModelUserAccess::Controller }
    ActiveSupport.on_load(:action_view) { include ActiveScaffold::Bridges::Cancan::AssociationHelpers }
    ActiveSupport.on_load(:active_record) { include ActiveScaffold::Bridges::Cancan::ModelUserAccess::Model }
    ActiveSupport.on_load(:active_record) { include ActiveScaffold::Bridges::Cancan::ActiveRecord }
  end

  def self.install?
    Object.const_defined? :CanCan
  end
end
