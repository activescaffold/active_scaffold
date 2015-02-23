class ActiveScaffold::Bridges::Carrierwave < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'carrierwave/form_ui')
    require File.join(File.dirname(__FILE__), 'carrierwave/list_ui')
    require File.join(File.dirname(__FILE__), 'carrierwave/carrierwave_bridge_helpers')
    require File.join(File.dirname(__FILE__), 'carrierwave/carrierwave_bridge')
    ActiveScaffold::Config::Core.send :include, ActiveScaffold::Bridges::Carrierwave::CarrierwaveBridge
  end
  def self.install?
    Object.const_defined? 'CarrierWave'
  end
end
