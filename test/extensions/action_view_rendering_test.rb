require 'test_helper'

class ActionViewRenderingTest < ActionController::TestCase
  setup do
    @controller = PeopleController.new
  end

  test 'render :super twice' do
    get :index
    assert_select '#controller', 1
    assert_select '#app', 1
  end

  test 'render partial override with render :super twice' do
    get :new
    assert_select '#first_name_field', 1
    assert_select '#controller_form', 1
    assert_select '#app_form', 1
  end
end

class RenderInTest < ActionView::TestCase
  # Mock renderable object that implements render_in
  class SimpleRenderable
    def render_in(view_context)
      view_context.tag.div('Simple renderable content', class: 'simple-renderable')
    end
  end

  # Mock renderable with more complex behavior (like ViewComponent)
  class ComplexRenderable
    attr_reader :title, :content

    def initialize(title:, content:)
      @title = title
      @content = content
    end

    def render_in(view_context)
      view_context.tag.div(class: 'complex-renderable') do
        view_context.tag.h1(@title) + view_context.tag.p(@content)
      end
    end
  end

  # Mock TurboStream-like renderable
  class TurboStreamRenderable
    def render_in(view_context)
      view_context.tag.turbo_stream(action: 'replace', target: 'test') do
        view_context.tag.template { 'Updated content' }
      end
    end
  end

  test 'render simple object with render_in' do
    result = render(SimpleRenderable.new)
    assert_match(/Simple renderable content/, result)
    assert_match(/simple-renderable/, result)
  end

  test 'render complex object with render_in' do
    renderable = ComplexRenderable.new(title: 'Test Title', content: 'Test content')
    result = render(renderable)
    assert_match(/Test Title/, result)
    assert_match(/Test content/, result)
    assert_match(/complex-renderable/, result)
  end

  test 'render turbo stream like object with render_in' do
    result = render(TurboStreamRenderable.new)
    assert_match(/turbo-stream/, result)
    assert_match(/Updated content/, result)
  end

  test 'render_in has access to view context helpers' do
    renderable = SimpleRenderable.new
    result = render(renderable)
    # The result should be an HTML safe string since we used tag helpers
    assert result.html_safe?
  end

  test 'render with hash options still works' do
    # Ensure backwards compatibility - rendering with hash options should still work
    result = render(inline: '<div class="inline-test">Inline content</div>')
    assert_match(/Inline content/, result)
    assert_match(/inline-test/, result)
  end

  test 'render with partial name still works' do
    # Create a mock partial for testing
    with_partial('_test_partial', '<div class="partial-test">Partial content</div>') do
      result = render(partial: 'test_partial')
      assert_match(/Partial content/, result)
      assert_match(/partial-test/, result)
    end
  end

  test 'render_in method receives correct view context' do
    # Test that the view context passed to render_in is correct
    received_context = nil
    renderable = Class.new do
      define_method(:render_in) do |view_context|
        received_context = view_context
        '<div>test</div>'.html_safe
      end
    end.new

    render(renderable)
    assert_not_nil received_context
    assert_respond_to received_context, :tag
    assert_respond_to received_context, :content_tag
  end

  test 'render_in return value is used as output' do
    custom_output = '<div class="custom-output">Custom!</div>'.html_safe
    renderable = Class.new do
      define_method(:render_in) do |_|
        custom_output
      end
    end.new

    result = render(renderable)
    assert_equal custom_output, result
    assert_match(/Custom!/, result)
    assert_match(/custom-output/, result)
  end

  private

  def with_partial(name, content)
    # Helper method to temporarily create a partial for testing
    partial_dir = Rails.root.join('app/views')
    partial_path = partial_dir.join(name)

    begin
      FileUtils.mkdir_p(partial_dir)
      File.write(partial_path, content)
      yield
    ensure
      File.delete(partial_path) if File.exist?(partial_path)
    end
  end
end
