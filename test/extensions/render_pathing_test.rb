require File.join(File.dirname(__FILE__), '../test_helper.rb')

##
## Stubs and Configuration
##

# need to stub out the template_exists? method so we can test what paths it receives
ActionController::Base.template_root = 'app/views'
class ActionView::Base
  attr_accessor :template_paths
  def initialize
    @base_path = ActionController::Base.template_root = 'app/views'
  end

  def template_exists?(template_path, extension)
    return unless extension == :rhtml
    self.template_paths << full_template_path(template_path, extension)
    false
  end
end

# need to initialize and provide access to the @template
class CurrentController < ActionController::Base
  attr_accessor :template
  def initialize
    @template = ActionView::Base.new
    @template.controller = self
  end
end

# without setting the frontend we wouldn't be able to test current frontend vs default frontend templates
ActiveScaffold::Config::Core.frontend = 'some_frontend'

class TemplateSearchingTest < Test::Unit::TestCase
  def setup
    @controller = CurrentController.new
    @template = @controller.template
  end

  def test_our_templates_from_controller
    @template.template_paths = []
    @controller.send(:rewrite_template_path_for_active_scaffold, 'create_form')
    assert_equal ['app/views/current/create_form.rhtml',
                  'app/views/active_scaffold_overrides/create_form.rhtml',
                  'app/views/../../vendor/plugins/'+ActiveScaffold::Config::Core.plugin_directory+'/frontends/some_frontend/views/create_form.rhtml',
                  'app/views/../../vendor/plugins/'+ActiveScaffold::Config::Core.plugin_directory+'/frontends/default/views/create_form.rhtml'],
                 @template.template_paths
  end

  def test_other_templates_from_controller
    # test a regular file. should get something from the current controller's path ... everything after doesn't matter
    @template.template_paths = []
    @controller.send(:rewrite_template_path_for_active_scaffold, 'my_page')
    assert_equal 'app/views/current/my_page.rhtml',
                 @template.template_paths.first

    # test a this-controller file. should get something from the specified controller's path ... everything after doesn't matter.
    @template.template_paths = []
    @controller.send(:rewrite_template_path_for_active_scaffold, 'current/my_page')
    assert_equal 'app/views/current/my_page.rhtml',
                 @template.template_paths.first

    # note: not testing an other-controller file, because render :action specifically does NOT search other controllers
  end

  def test_our_templates_from_view
    @template.template_paths = []
    @template.send(:rewrite_partial_path_for_active_scaffold, 'create_form')
    assert_equal ['app/views/current/_create_form.rhtml',
                  'app/views/active_scaffold_overrides/_create_form.rhtml',
                  'app/views/../../vendor/plugins/'+ActiveScaffold::Config::Core.plugin_directory+'/frontends/some_frontend/views/_create_form.rhtml',
                  'app/views/../../vendor/plugins/'+ActiveScaffold::Config::Core.plugin_directory+'/frontends/default/views/_create_form.rhtml'],
                 @template.template_paths
  end

  def test_other_templates_from_view
    # test a regular file. should get something from the current controller's path ... everything after doesn't matter
    @template.template_paths = []
    @template.send(:rewrite_partial_path_for_active_scaffold, 'summary')
    assert_equal 'app/views/current/_summary.rhtml',
                 @template.template_paths.first

    # test a this-controller file. should get something from the specified controller's path ... everything after doesn't matter.
    @template.template_paths = []
    @template.send(:rewrite_partial_path_for_active_scaffold, 'current/summary')
    assert_equal 'app/views/current/_summary.rhtml',
                 @template.template_paths.first

    # test a this-controller file. should get something from the specified controller's path ... everything after doesn't matter.
    @template.template_paths = []
    @template.send(:rewrite_partial_path_for_active_scaffold, 'other/summary')
    assert_equal 'app/views/other/_summary.rhtml',
                 @template.template_paths.first
  end
end