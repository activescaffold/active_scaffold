class ActiveScaffold::Bridges::RecordSelect < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'record_select/helpers.rb')
  end
  def self.stylesheets
    'record_select'
  end
  def self.javascripts
    'record_select'
  end
end
