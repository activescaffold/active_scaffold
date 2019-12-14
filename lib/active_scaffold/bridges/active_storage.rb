class ActiveScaffold::Bridges::ActiveStorage < ActiveScaffold::DataStructures::Bridge
  def self.install
    Dir[File.join(__dir__, 'active_storage', '*.rb')].each { |file| require file }
    ActiveScaffold::Config::Core.send :prepend, ActiveScaffold::Bridges::ActiveStorage::ActiveStorageBridge
  end
end
