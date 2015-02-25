module ActiveScaffold::DataStructures
  class Bridge
    def self.install
      raise RunTimeError, "install not defined for bridge #{name}"
    end

    def self.prepare
    end

    # by convention and default, use the bridge name as the required constant for installation
    def self.install?
      Object.const_defined? name.demodulize
    end

    def self.run
      install if install?
    end

    def self.stylesheets
    end

    def self.javascripts
    end
  end
end
