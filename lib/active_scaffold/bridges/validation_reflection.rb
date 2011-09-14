class ActiveScaffold::Bridges::ValidationReflection < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), "validation_reflection/validation_reflection_bridge.rb")
    ActiveScaffold::DataStructures::Column.class_eval { include ActiveScaffold::ValidationReflectionBridge }
  end
  def self.install?
    ActiveRecord::Base.respond_to? :reflect_on_validations_for
  end
end
