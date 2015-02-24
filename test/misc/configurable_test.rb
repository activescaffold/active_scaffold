require 'test_helper'

class ConfigurableClass
  FOO = 'bar'
  def foo; FOO end
  def self.foo; FOO end
end

class IncludedClass < ConfigurableClass
  include ActiveScaffold::Configurable
end

class ExtendedClass < ConfigurableClass
  extend ActiveScaffold::Configurable
end

class ConfigurableTest < MiniTest::Test
  ##
  ## constants and methods for tests to check against
  ##
  def hello; 'world' end
  HELLO = 'world'

  def test_instance_configuration
    configurable_class = IncludedClass.new

    ##
    ## sanity checks
    ##
    # make sure the configure method is available
    assert configurable_class.respond_to?(:configure)
    # make sure real functions still work
    assert_equal 'bar', configurable_class.foo
    # make sure other functions still don't work
    assert_raises NoMethodError do
      configurable_class.i_do_not_exist
    end

    ##
    ## test normal block behaviors
    ##
    # functions
    assert_equal hello, configurable_class.configure { hello }
    # variables
    assert_equal configurable_class, configurable_class.configure { configurable_class }
    # constants
    assert_equal ConfigurableTest::HELLO, configurable_class.configure { ConfigurableTest::HELLO }

    ##
    ## test extra "localized" block behavior
    ##
    # functions
    assert_equal configurable_class.foo, configurable_class.configure { foo }
    # constants - not working
    #    assert_equal configurable_class.FOO, configurable_class.configure {FOO}
  end

  def test_class_configuration
    ##
    ## sanity checks
    ##
    # make sure the configure method is available
    assert ExtendedClass.respond_to?(:configure)
    # make sure real functions still work
    assert_equal 'bar', ExtendedClass.foo
    # make sure other functions still don't work
    assert_raises NoMethodError do
      ExtendedClass.i_do_not_exist
    end

    ##
    ## test normal block behaviors
    ##
    # functions
    assert_equal hello, ExtendedClass.configure { hello }
    # variables
    assert_equal ExtendedClass, ExtendedClass.configure { ExtendedClass }
    # constants
    assert_equal ConfigurableTest::HELLO, ExtendedClass.configure { ConfigurableTest::HELLO }

    ##
    ## test extra "localized" block behavior
    ##
    # functions
    assert_equal ExtendedClass.foo, ExtendedClass.configure { foo }
    # constants - not working
    #    assert_equal ExtendedClass.FOO, ExtendedClass.configure {FOO}
  end

  def test_arity
    # this is the main style
    assert_equal 'foo', ExtendedClass.configure { 'foo' }
    # but we want to let people accept the configurable class as the first argument, too
    assert_equal 'bar', ExtendedClass.configure { |a| a.foo } # rubocop:disable Style/SymbolProc
  end
end
