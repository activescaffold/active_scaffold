class ConstMocker
  def initialize(const_name, parent = Object)
    @parent = parent
    @const_name = const_name
    @const_state = nil
    @const_state = @parent.const_defined?(@const_name) ? @parent.const_get(@const_name) : nil
  end

  def remove
    @parent.send :remove_const, @const_name if @parent.const_defined?(@const_name)
  end

  def declare
    @parent.const_set @const_name, Class.new
  end

  def restore
    remove
    @parent.const_set @const_name, @const_state if @const_state
  end

  def const
    @parent.const_get @const_name if @parent.const_defined?(@const_name)
  end

  def self.mock(const_name, parent = Object, &block)
    cm = new(const_name, parent)
    yield(cm)
    cm.restore
    true
  end
end
