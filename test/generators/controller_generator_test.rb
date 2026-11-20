# frozen_string_literal: true

require 'test_helper'
require 'generators/active_scaffold/controller/controller_generator'
require 'tmpdir'

class ControllerGeneratorTest < Minitest::Test
  def setup
    @destination = Dir.mktmpdir('active-scaffold-controller-generator')
  end

  def teardown
    FileUtils.remove_entry @destination
  end

  def test_generates_controller_helper_and_view_directory
    run_generator 'Post'

    assert_file_contains 'app/controllers/posts_controller.rb', 'class PostsController < ApplicationController'
    assert_file_contains 'app/controllers/posts_controller.rb', 'active_scaffold :"post" do |conf|'
    assert_file_contains 'app/helpers/posts_helper.rb', 'module PostsHelper'
    assert_path_exists 'app/views/posts'
  end

  def test_generates_namespaced_controller_helper_and_view_directory
    run_generator 'Admin::Post'

    assert_file_contains 'app/controllers/admin/posts_controller.rb',
                         'class Admin::PostsController < ApplicationController'
    assert_file_contains 'app/controllers/admin/posts_controller.rb', 'active_scaffold :"admin/post" do |conf|'
    assert_file_contains 'app/helpers/admin/posts_helper.rb', 'module Admin::PostsHelper'
    assert_path_exists 'app/views/admin/posts'
  end

  private

  def run_generator(name)
    generator = ActiveScaffold::Generators::ControllerGenerator.new(
      [name], {orm: 'active_record', test_framework: nil}, destination_root: @destination
    )
    Dir.chdir(@destination) { generator.invoke_all }
  end

  def read(path)
    File.binread File.join(@destination, path)
  end

  def assert_file_contains(path, content)
    assert_includes read(path), content
  end

  def assert_path_exists(path)
    assert File.exist?(File.join(@destination, path)), "Expected #{path} to exist"
  end
end
