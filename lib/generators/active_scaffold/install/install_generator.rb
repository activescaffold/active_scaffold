# frozen_string_literal: true

require 'rails/generators/base'
# require 'generators/active_scaffold_controller/active_scaffold_controller_generator'

module ActiveScaffold
  module Generators
    class InstallGenerator < Rails::Generators::Base
      def self.base_root
        File.expand_path '../..', __dir__
      end

      def add_concern_routes
        route 'concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)'
        route 'concern :active_scaffold_association, ActiveScaffold::Routing::Association.new'
      end

      IMPORTMAP = 'config/importmap.rb'
      JS_ASSET = 'app/assets/javascripts/application.js'
      JS_APP = 'app/javascript/application.js'
      MANIFEST = 'app/assets/config/manifest.js'

      def add_javascript
        if File.exist?(IMPORTMAP)
          add_to_importmap
          add_to_js_app
        elsif File.exist?(JS_ASSET) # rails 6.1
          original_js = File.binread(JS_ASSET)
          if original_js.include?('require active_scaffold')
            say_status('skipped', "insert into #{JS_ASSET}", :yellow)
          else
            insert_into_file JS_ASSET, after: %r{//= require +.*ujs['"]?\n} do
              "//= require active_scaffold\n"
            end
            add_to_manifest 'active_scaffold/manifest.js'
          end
          setup_jquery JS_ASSET, original_js
        else
          create_javascript_manifest JS_ASSET
        end
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

      def add_to_importmap
        original_js = File.binread(IMPORTMAP)
        if original_js.match?(/^pin +['"]active_scaffold['"](?=,|$)/)
          say_status('skipped', "append active_scaffold to #{IMPORTMAP}", :yellow)
        else
          append_to_file IMPORTMAP do
            "pin 'active_scaffold'\n"
          end
        end
        if Object.const_defined?(:Jquery)
          if original_js.match?(/^pin +['"]jquery['"](?=,|$)/)
            say_status('skipped', "append jquery to #{IMPORTMAP}", :yellow)
          else
            append_to_file IMPORTMAP do
              "pin 'jquery'\n"
            end
          end
          if original_js.match?(%r{^pin +['"](jquery_ujs|@rails/ujs)['"](?=,|$)})
            say_status('skipped', "append jquery_ujs to #{IMPORTMAP}", :yellow)
          else
            append_to_file IMPORTMAP do
              "pin 'jquery_ujs'\n"
            end
          end
        else
          say_status('missing', 'no jquery-rails gem, load jquery, and jquery_ujs or @rails/ujs, in your layout, or add jquery-rails ' \
                                "to Gemfile and add pin \"jquery\" and pin \"jquery_ujs\" or pin \"@rails/ujs\", to #{IMPORTMAP}", :red)
        end
      end

      def add_to_js_app
        original_js = File.binread(JS_APP)
        if original_js.match?(/^import +['"]active_scaffold['"]/)
          say_status('skipped', "append active_scaffold to #{JS_APP}", :yellow)
        else
          append_to_file JS_APP do
            "import 'active_scaffold'\n"
          end
        end
        manifest = ['active_scaffold/manifest.js']
        if Object.const_defined?(:Jquery)
          if original_js.match?(/^import +['"]jquery['"]/)
            say_status('skipped', "append jquery to #{JS_APP}", :yellow)
          else
            manifest << 'jquery.js'
            insert_into_file JS_APP, before: /import +['"]active_scaffold['"]\n/ do
              "import 'jquery'\n"
            end
          end
          if original_js.match?(%r{^import +(['"]jquery_ujs['"]|Rails from ['"]@rails/ujs['"])})
            say_status('skipped', "append jquery_ujs to #{JS_APP}", :yellow)
          else
            manifest << 'jquery_ujs.js'
            insert_into_file JS_APP, before: /import +['"]active_scaffold['"]\n/ do
              "import 'jquery_ujs'\n"
            end
          end
        end
        add_to_manifest(*manifest)
      end

      def create_javascript_manifest(file)
        FileUtils.mkdir_p File.dirname(file)
        js_content = "// This is a manifest file that'll be compiled into application.js, which will include all the files
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
        File.open(file, 'w') { |f| f << js_content } unless options[:pretend]
        say_status('create', file)
        insert_into_file 'app/views/layouts/application.html.erb', after: /javascript_pack_tag 'application'.*\n/ do
          "    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload', 'data-turbo-track': 'reload' %>\n"
        end
        add_to_manifest 'application.js', 'active_scaffold/manifest.js'
        setup_jquery file, js_content, where: 'active_scaffold'
      end

      def add_to_manifest(*files)
        append_to_file MANIFEST do
          files.map { |file| "//= link #{file}\n" }.join
        end
      end

      def setup_jquery(file, original_js = nil, where: 'ujs')
        original_js ||= File.binread(file)
        if Object.const_defined?(:Jquery)
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
