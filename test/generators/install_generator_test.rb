# frozen_string_literal: true

require 'test_helper'
require 'generators/active_scaffold/install/install_generator'
require 'tmpdir'

class InstallGeneratorTest < Minitest::Test
  def setup
    @destination = Dir.mktmpdir('active-scaffold-install-generator')
    write 'config/routes.rb', "Rails.application.routes.draw do\nend\n"
    write 'app/views/layouts/application.html.erb', <<~ERB
      <!DOCTYPE html>
      <html>
        <head>
        </head>
        <body></body>
      </html>
    ERB
  end

  def teardown
    FileUtils.remove_entry @destination
  end

  def test_propshaft_with_importmap_adds_pins_imports_and_layout_helpers
    write 'config/importmap.rb', "pin 'application'\npin 'active_scaffold'\n"
    write 'app/javascript/application.js', "import '@hotwired/turbo-rails'\n"

    run_generator :propshaft

    assert_file_contains 'config/importmap.rb', "pin 'active_scaffold', to: 'active_scaffold/load.js'"
    assert_file_contains 'config/importmap.rb', "pin 'jquery'"
    assert_file_contains 'config/importmap.rb', "pin 'jquery_ujs'"
    assert_file_contains 'app/javascript/application.js', "import 'jquery'\nimport 'jquery_ujs'\nimport 'active_scaffold'"
    assert_file_contains 'app/views/layouts/application.html.erb', '<%= javascript_importmap_tags %>'
    assert_file_contains 'app/views/layouts/application.html.erb', '<%= active_scaffold_javascript_tag %>'
    assert_equal 1, read('config/importmap.rb').scan(/^pin 'active_scaffold'/).size
    assert_file_contains 'app/views/layouts/application.html.erb', "<head>\n    <%= javascript_importmap_tags %>"
    refute_path_exists 'app/assets/config/manifest.js'

    run_javascript_generator :propshaft

    assert_equal 1, read('config/importmap.rb').scan(/^pin 'active_scaffold'/).size
    assert_equal 1, read('app/javascript/application.js').scan(/^import 'active_scaffold'/).size
    assert_equal 1, read('app/views/layouts/application.html.erb').scan('active_scaffold_javascript_tag').size
  end

  def test_sprockets_with_importmap_uses_asset_manifest_without_layout_helper
    write 'config/importmap.rb', "pin 'application'\n"
    write 'app/javascript/application.js', "import '@hotwired/turbo-rails'\n"
    write 'app/assets/config/manifest.js', "//= link_tree ../images\n"

    run_generator :sprockets

    assert_file_contains 'config/importmap.rb', "pin 'active_scaffold'\n"
    refute_file_contains 'config/importmap.rb', 'active_scaffold/load.js'
    assert_file_contains 'app/assets/config/manifest.js', '//= link active_scaffold/manifest.js'
    refute_file_contains 'app/views/layouts/application.html.erb', 'active_scaffold_javascript_tag'
  end

  def test_importmap_requires_application_javascript_entrypoint
    write 'config/importmap.rb', "pin 'application'\n"

    error = assert_raises(Thor::Error) { run_javascript_generator :propshaft }

    assert_equal 'Unable to configure import maps: app/javascript/application.js does not exist', error.message
  end

  def test_propshaft_without_importmap_adds_javascript_tags_to_layout
    write 'app/javascript/application.js', "import '@hotwired/turbo-rails'\n"

    run_generator :propshaft

    assert_file_contains 'app/views/layouts/application.html.erb', "<%= javascript_include_tag 'jquery', 'jquery_ujs' %>"
    assert_file_contains 'app/views/layouts/application.html.erb', '<%= active_scaffold_javascript_tag %>'
    refute_path_exists 'app/assets/javascripts/application.js'
  end

  def test_sprockets_without_importmap_updates_javascript_and_asset_manifests
    write 'app/assets/javascripts/application.js', "//= require rails-ujs\n"
    write 'app/javascript/application.js', "import '@hotwired/turbo-rails'\n"
    write 'app/assets/config/manifest.js', "//= link_tree ../images\n"

    run_generator :sprockets

    assert_file_contains 'app/assets/javascripts/application.js', '//= require jquery'
    assert_file_contains 'app/assets/javascripts/application.js', '//= require active_scaffold'
    assert_file_contains 'app/assets/config/manifest.js', '//= link active_scaffold/manifest.js'
    refute_file_contains 'app/javascript/application.js', 'active_scaffold'
    refute_file_contains 'app/views/layouts/application.html.erb', 'active_scaffold_javascript_tag'
  end

  def test_dartsass_rails_adds_propshaft_scss_entrypoint
    write 'app/assets/stylesheets/application.scss', "body { color: black; }\n"

    run_stylesheet_generator 'active_scaffold/core'

    assert_equal "@use 'active_scaffold/core';\nbody { color: black; }\n", read('app/assets/stylesheets/application.scss')
  end

  def test_dartsass_sprockets_adds_sprockets_scss_entrypoint
    write 'app/assets/stylesheets/application.scss', "body { color: black; }\n"

    run_stylesheet_generator 'active_scaffold'

    assert_equal "@use 'active_scaffold';\nbody { color: black; }\n", read('app/assets/stylesheets/application.scss')
  end

  def test_sprockets_css_erb_manifest_is_supported
    write 'app/assets/stylesheets/application.css.erb', "/*\n *= require_tree .\n */\n"

    run_stylesheet_generator nil

    assert_file_contains 'app/assets/stylesheets/application.css.erb', ' *= require active_scaffold'
  end

  private

  def run_generator(pipeline)
    generator = build_generator
    generator.define_singleton_method(:asset_pipeline) { pipeline }
    Dir.chdir(@destination) { generator.invoke_all }
  end

  def run_stylesheet_generator(dependency)
    generator = build_generator
    generator.define_singleton_method(:scss_dependency) { dependency }
    Dir.chdir(@destination) { generator.add_stylesheet }
  end

  def run_javascript_generator(pipeline)
    generator = build_generator
    generator.define_singleton_method(:asset_pipeline) { pipeline }
    Dir.chdir(@destination) { generator.add_javascript }
  end

  def build_generator
    ActiveScaffold::Generators::InstallGenerator.new([], {}, destination_root: @destination)
  end

  def write(path, content)
    full_path = File.join(@destination, path)
    FileUtils.mkdir_p File.dirname(full_path)
    File.binwrite full_path, content
  end

  def read(path)
    File.binread File.join(@destination, path)
  end

  def assert_file_contains(path, content)
    assert_includes read(path), content
  end

  def refute_file_contains(path, content)
    assert_equal false, read(path).include?(content)
  end

  def refute_path_exists(path)
    assert_equal false, File.exist?(File.join(@destination, path))
  end
end
