# frozen_string_literal: true

class ActiveScaffold::Bridges::ActiveStorage < ActiveScaffold::DataStructures::Bridge
  cattr_accessor :thumbnail_variant
  self.thumbnail_variant = {resize_to_limit: [nil, 30]}

  def self.install
    Dir[File.join(__dir__, 'active_storage', '*.rb')].each { |file| require file }
    ActiveScaffold::Config::Core.prepend ActiveScaffold::Bridges::ActiveStorage::ActiveStorageBridge
  end
end
