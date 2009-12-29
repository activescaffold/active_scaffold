require File.join(File.dirname(__FILE__), '../test_helper.rb')

class ClassWithFinder
  include ActiveScaffold::Finder
  def conditions_for_collection; end
  def conditions_from_params; end
  def conditions_from_constraints; end
  def joins_for_collection; end
  def custom_finder_options
    {}
  end
  def named_scopes_for_collection
    nil
  end
end

class NamedScopeTest < Test::Unit::TestCase
  def setup
    @klass = ClassWithFinder.new
    @klass.stubs(:active_scaffold_config).returns(mock { stubs(:model).returns(ModelStub) })
    @klass.stubs(:active_scaffold_session_storage).returns({})
    ModelStub.nested_scope_calls.clear
  end

  def test_named_scope_as_symbol
    @klass.instance_eval do
      def named_scopes_for_collection
        :a_is_defined
      end
    end
    model = @klass.send(:model_with_named_scope)
    assert_equal 1, model.nested_scope_calls.length
  end

  def test_named_scope_as_string
    @klass.instance_eval do
      def named_scopes_for_collection
        "a_is_defined.b_like('hello')"
      end
    end
    model = @klass.send(:model_with_named_scope)
    assert_equal 2, model.nested_scope_calls.length
    assert_equal :a_is_defined, model.nested_scope_calls.first
    assert_equal :b_like, model.nested_scope_calls.last
  end
  
  def test_named_scope_as_array
    @klass.instance_eval do
      def named_scopes_for_collection
        [:b_like, 'hello']
      end
    end
    model = @klass.send(:model_with_named_scope)
    assert_equal 1, model.nested_scope_calls.length
    assert_equal :b_like, model.nested_scope_calls.first
  end
  
  def test_named_scope_as_array_of_array
    @klass.instance_eval do
      def named_scopes_for_collection
        [[:b_like, 'hello'], [:a_is_defined]]
      end
    end
    model = @klass.send(:model_with_named_scope)
    assert_equal 2, model.nested_scope_calls.length
    assert_equal :b_like, model.nested_scope_calls.first
    assert_equal :a_is_defined, model.nested_scope_calls.last
  end
end
