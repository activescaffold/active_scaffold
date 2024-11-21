require 'rails/generators/base'
# require 'generators/active_scaffold_controller/active_scaffold_controller_generator'

module ActiveScaffold
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc 'Add concerns to routes and require lines to assets manifest files'

      def add_concern_routes
        route 'concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)'
        route 'concern :active_scaffold_association, ActiveScaffold::Routing::Association.new'
      end

      def add_to_javascript_manifest
        file = 'app/assets/javascripts/application.js'
        unless File.exist?(file)
          create_javascript_manifest file
          return
        end
        original_js = File.binread(file)
        if original_js.include?('require active_scaffold')
          say_status('skipped', "insert into #{file}", :yellow)
        else
          insert_into_file file, after: %r{//= require +.*ujs['"]?\n} do
            "//= require active_scaffold\n"
          end
        end
        setup_jquery file, original_js
      end

      def add_to_stylesheet_manifest
        file = 'app/assets/stylesheets/application.css'
        return unless File.exist?(file)
        original_css = File.binread(file)
        if original_css.match?(/require active_scaffold$/)
          say_status('skipped', 'insert into app/assets/stylesheets/application.css', :yellow)
        else
          insert_into_file 'app/assets/stylesheets/application.css', before: %r{[ ]*\*/} do
            " *= require active_scaffold\n"
          end
        end
      end

      protected

      def create_javascript_manifest(file)
        FileUtils.mkdir_p File.dirname(file)
        File.open(file, 'w') do |f|
          f << "// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require active_scaffold
"
          say_status('create', file)
        end
        insert_into_file 'app/views/layouts/application.html.erb', after: /javascript_pack_tag 'application'.*\n/ do
          "    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload', 'data-turbo-track': 'reload' %>\n"
        end
        append_to_file 'config/initializers/assets.rb' do
          "Rails.application.config.assets.precompile += %w( application.js )\n"
        end
        setup_jquery file, where: 'active_scaffold'
      end

      def setup_jquery(file, original_js = nil, where: 'ujs')
        original_js ||= File.binread(file)
        if defined? Jquery
          unless original_js.include?('require jquery')
            insert_into_file file, before: %r{//= require +.*#{where}['"]?\n} do
              "//= require jquery\n"
            end
          end
        else
          say_status('missing', 'no jquery-rails gem, load jquery in your layout, or add jquery-rails to Gemfile and add //= require jquery to application.js', :red)
        end
      end
    end
  end
end
