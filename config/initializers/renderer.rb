# http://railsguides.net/2012/08/29/rails3-does-not-render-partial-for-specific-format/
class ActionView::PartialRenderer
  private
  def setup_with_formats(context, options, block)
    formats = Array(options[:formats])
    @lookup_context.formats = formats | @lookup_context.formats
    setup_without_formats(context, options, block)
  end

  alias_method_chain :setup, :formats
end