# simple implementation of shared_examples and include_examples per https://gist.github.com/jodosha/1560208
# note: if you change files in test/support, restart Spork because they are loaded in the Spork.prefork block

require 'minitest/spec'
require 'minitest/autorun'

MiniTest::Spec.class_eval do
  def self.shared_examples
    @shared_examples ||= {}
  end
end

module Kernel
  def shared_examples(desc, &block)
    MiniTest::Spec.shared_examples[desc] = block
  end

  def include_examples(desc, *options)
    self.instance_exec(*options, &MiniTest::Spec.shared_examples[desc])
  end
end
