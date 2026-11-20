# frozen_string_literal: true

require 'test_helper'
require 'generators/active_scaffold/resource/resource_generator'
require 'generators/active_scaffold/controller/controller_generator'
require 'tmpdir'

class ResourceGeneratorTest < Minitest::Test
  def setup
    @destination = Dir.mktmpdir('active-scaffold-resource-generator')
    write 'config/routes.rb', <<~RUBY
      Rails.application.routes.draw do
        concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)
      end
    RUBY
  end

  def teardown
    FileUtils.remove_entry @destination
  end

  def test_generates_resource_controller_and_active_scaffold_route
    run_generator 'Post', 'title:string'

    assert_file_contains 'app/models/post.rb', 'class Post < ApplicationRecord'
    assert_file_contains 'app/controllers/posts_controller.rb', 'active_scaffold :"post" do |conf|'
    assert_file_contains 'config/routes.rb', 'resources :posts, concerns: :active_scaffold'
  end

  def test_generates_namespaced_active_scaffold_route
    run_generator 'Admin::Post'

    assert_file_contains 'app/controllers/admin/posts_controller.rb', 'active_scaffold :"admin/post" do |conf|'
    assert_file_contains 'config/routes.rb',
                         'namespace :admin do resources :posts, concerns: :active_scaffold end'
  end

  private

  def run_generator(*arguments)
    generator = ActiveScaffold::Generators::ResourceGenerator.new(
      arguments, {orm: 'active_record', test_framework: nil}, destination_root: @destination
    )
    Dir.chdir(@destination) { generator.invoke_all }
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
end
