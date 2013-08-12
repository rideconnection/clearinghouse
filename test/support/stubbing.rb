# this allows a MiniTest test to stub out a method on all instances of a class
# without this, it is only possible to stub methods on specific instances and class methods
#
# examples:
#
# MyClass.all_instances.stub(:foo, 'bar') do
#   MyClass.new.foo.must_equal 'bar'
# end
#
# MyClass.all_instances.stub(:foo, 'bar')
# MyClass.new.foo.must_equal 'bar'
# MyClass.all_instances.unstub(:foo, 'bar')

class AllInstances
  def initialize(klass)
    @klass = klass
    @@new_method_names ||= {}
  end

  def stub(method_name, return_value)
    @@new_method_names[method_name] = "_original_#{method_name}".to_sym
    @klass.send(:alias_method, @@new_method_names[method_name], method_name)
    @klass.send(:define_method, method_name, ->(*args){ return_value })
    if block_given?
      begin
        yield
      ensure
        unstub(method_name)
      end
    end
  end

  def unstub(method_name)
    @klass.send(:remove_method, method_name)
    @klass.send(:alias_method, method_name, @@new_method_names[method_name])
    @@new_method_names[method_name] = nil
  end
end

class Class
  def all_instances
    AllInstances.new(self)
  end
end
