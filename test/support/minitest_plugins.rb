# # include this module in any test class to get shared setup and teardown behaviors
#
# module MinitestPlugins
#   def before_setup
#     super
#     # code to run before all test cases
#   end
#
#   def after_teardown
#     # code to run after all test cases
#     super
#   end
# end
#
# class MiniTest::Unit::TestCase
#   include MinitestPlugins
# end
