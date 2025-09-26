# frozen_string_literal: true

class ActiveScaffold::Bridges::Bitfields < ActiveScaffold::DataStructures::Bridge
  def self.install
    Dir[File.join(__dir__, 'bitfields', '*.rb')].each { |file| require file }
    ActiveScaffold::Config::Core.prepend ActiveScaffold::Bridges::Bitfields::BitfieldsBridge
    ActiveScaffold::Config::Core.after_config_callbacks << :_setup_bitfields
  end
end
