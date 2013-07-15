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
    @parent.const_set @const_name, Class.new unless @parent.const_defined?(@const_name)
  end
  
  def restore
    remove
    @parent.const_set @const_name, @const_state if @const_state
  end

  def const
    @parent.const_get @const_name
  end
  
  def self.mock(*const_names, &block)
    cm = new(*const_names)
    yield(cm)
    cm.restore
    true
  end
end
