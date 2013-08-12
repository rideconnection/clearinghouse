# this allows a MiniTest test to stub out a method on all instances of a class
# without this, it is only possible to stub methods on specific instances and class methods

class AllInstances
  def initialize(klass)
    @klass = klass
  end

  def stub(method_name, return_value, &block)
    @new_method = "_original_#{method_name}".to_sym
    @klass.send(:alias_method, @new_method, method_name)
    @klass.send(:define_method, method_name, ->(*args){ return_value })
    block.call
    @klass.send(:remove_method, method_name)
    @klass.send(:alias_method, method_name, @new_method)
  end
end

class Class
  def all_instances
    AllInstances.new(self)
  end
end
