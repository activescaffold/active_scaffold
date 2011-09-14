module ActiveScaffold
  module Bridges
    class Carrierwave
      module CarrierwaveBridgeHelpers
        mattr_accessor :thumbnail_style
        self.thumbnail_style = :thumbnail
      end
    end
  end
end
