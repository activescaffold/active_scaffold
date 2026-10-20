# frozen_string_literal: true

require 'rails/generators/base'

module ActiveScaffold
  module Generators
    class InstallGenerator < Rails::Generators::Base
      IMPORTMAP = 'config/importmap.rb'
      JS_ASSET = 'app/assets/javascripts/application.js'
      JS_APP = 'app/javascript/application.js'
      LAYOUT = 'app/views/layouts/application.html.erb'
      MANIFEST = 'app/assets/config/manifest.js'
      SCSS_ASSET = 'app/assets/stylesheets/application.scss'
      CSS_ASSETS = %w[app/assets/stylesheets/application.css app/assets/stylesheets/application.css.erb].freeze

      def self.base_root
        File.expand_path '../..', __dir__
      end

      def add_concern_routes
        route 'concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)'
        route 'concern :active_scaffold_association, ActiveScaffold::Routing::Association.new'
      end

      def add_javascript
        if File.exist?(IMPORTMAP)
          add_importmap_javascript
        elsif use_sprockets_javascript?
          add_sprockets_javascript
        elsif propshaft? || File.exist?(JS_APP)
          add_propshaft_javascript_tags
        else
          raise Thor::Error, 'Unable to configure ActiveScaffold JavaScript: no import map, Propshaft setup, ' \
                             "#{JS_APP}, or #{JS_ASSET} was found"
        end
      end

      def add_stylesheet
        if File.exist?(SCSS_ASSET)
          add_to_scss_asset
        else
          add_to_css_asset
        end
      end

      protected

      def add_importmap_javascript
        unless File.exist?(JS_APP)
          raise Thor::Error, "Unable to configure import maps: #{JS_APP} does not exist"
        end

        add_to_importmap
        add_to_js_app
        add_importmap_layout_tags if propshaft?
      end

      def add_to_importmap
        original_js = File.binread(IMPORTMAP)
        pin = propshaft? ? "pin 'active_scaffold', to: 'active_scaffold/load.js'" : "pin 'active_scaffold'"
        current_pin = original_js[/^pin +['"]active_scaffold['"].*$/, 0]
        if current_pin == pin
          say_status('skipped', "append active_scaffold to #{IMPORTMAP}", :yellow)
        elsif current_pin && generated_active_scaffold_pin?(current_pin)
          gsub_file IMPORTMAP, current_pin, pin
        else
          append_to_file IMPORTMAP, "#{pin}\n"
        end

        if jquery?
          add_importmap_pin original_js, 'jquery'
          add_importmap_pin original_js, 'jquery_ujs', alternatives: ['@rails/ujs']
        else
          say_status('missing', 'no jquery-rails gem; load jquery and jquery_ujs or @rails/ujs manually', :red)
        end
      end

      def add_importmap_pin(original_js, name, alternatives: [])
        names = [name, *alternatives].map { |item| Regexp.escape(item) }.join('|')
        if original_js.match?(/^pin +['"](?:#{names})['"](?=,|$)/)
          say_status('skipped', "append #{name} to #{IMPORTMAP}", :yellow)
        else
          append_to_file IMPORTMAP, "pin '#{name}'\n"
        end
      end

      def generated_active_scaffold_pin?(pin)
        pin.match?(%r{\Apin +['"]active_scaffold['"](?:, *to: *['"]active_scaffold/load\.js['"])?\z})
      end

      def add_to_js_app
        original_js = File.binread(JS_APP)
        add_js_import original_js, 'active_scaffold'
        manifest_files = ['active_scaffold/manifest.js']

        if jquery?
          unless js_import?(original_js, 'jquery')
            add_js_import original_js, 'jquery', before: 'active_scaffold'
            manifest_files << 'jquery.js'
          end
          unless original_js.match?(%r{^import +(['"]jquery_ujs['"]|Rails from ['"]@rails/ujs['"])})
            add_js_import original_js, 'jquery_ujs', before: 'active_scaffold'
            manifest_files << 'jquery_ujs.js'
          end
        end

        add_to_manifest(*manifest_files) if sprockets?
      end

      def add_js_import(original_js, name, before: nil)
        if js_import?(original_js, name)
          say_status('skipped', "add #{name} to #{JS_APP}", :yellow)
        elsif before
          insert_into_file JS_APP, "import '#{name}'\n", before: /^import +['"]#{Regexp.escape(before)}['"]\n/
        else
          append_to_file JS_APP, "import '#{name}'\n"
        end
      end

      def js_import?(content, name)
        content.match?(/^import +['"]#{Regexp.escape(name)}['"]/)
      end

      def add_importmap_layout_tags
        tags = []
        content = layout_content
        tags << '<%= javascript_importmap_tags %>' unless content.include?('javascript_importmap_tags')
        tags << '<%= active_scaffold_javascript_tag %>' unless content.include?('active_scaffold_javascript_tag')
        add_layout_tags tags
      end

      def add_propshaft_javascript_tags
        tags = []
        content = layout_content
        if jquery? && !content.match?(/javascript_include_tag .*jquery/)
          tags << "<%= javascript_include_tag 'jquery', 'jquery_ujs' %>"
        elsif !jquery?
          say_status('missing', 'no jquery-rails gem; load jquery and jquery_ujs or @rails/ujs in the layout', :red)
        end
        tags << '<%= active_scaffold_javascript_tag %>' unless content.include?('active_scaffold_javascript_tag')
        add_layout_tags tags
      end

      def layout_content
        unless File.exist?(LAYOUT)
          raise Thor::Error, "Unable to configure ActiveScaffold JavaScript: #{LAYOUT} does not exist"
        end

        File.binread(LAYOUT)
      end

      def add_layout_tags(tags)
        return if tags.empty?

        content = File.binread(LAYOUT)
        unless content.include?('</head>')
          raise Thor::Error, "Unable to configure ActiveScaffold JavaScript: no </head> tag found in #{LAYOUT}"
        end

        insert_into_file LAYOUT, tags.map { |tag| "    #{tag}\n" }.join, before: %r{^[ \t]*</head>}
      end

      def add_sprockets_javascript
        original_js = File.binread(JS_ASSET)
        unless original_js.match?(%r{//= require +active_scaffold(?:\s|$)})
          append_to_file JS_ASSET, "\n//= require active_scaffold\n"
        end
        setup_sprockets_jquery original_js
        add_to_manifest 'active_scaffold/manifest.js'
      end

      def use_sprockets_javascript?
        File.exist?(JS_ASSET) && (sprockets? || (!propshaft? && !File.exist?(JS_APP)))
      end

      def setup_sprockets_jquery(original_js)
        if jquery?
          return if original_js.match?(%r{//= require +jquery(?:\s|$)})

          insert_into_file JS_ASSET, "//= require jquery\n", before: %r{//= require +active_scaffold(?:\s|$)}
        else
          say_status('missing', 'no jquery-rails gem; load jquery manually before ActiveScaffold', :red)
        end
      end

      def add_to_manifest(*files)
        original_manifest = File.exist?(MANIFEST) ? File.binread(MANIFEST) : ''
        files.each do |file|
          next if original_manifest.match?(%r{^//= link #{Regexp.escape(file)}$})

          append_to_file MANIFEST, "//= link #{file}\n"
        end
      end

      def add_to_scss_asset
        dependency = scss_dependency
        unless dependency
          say_status('missing', "could not detect dartsass-rails or dartsass-sprockets; update #{SCSS_ASSET} manually", :red)
          return
        end

        original_scss = File.binread(SCSS_ASSET)
        if original_scss.match?(%r{^@use +['"]active_scaffold(?:/core)?['"]})
          say_status('skipped', "add ActiveScaffold to #{SCSS_ASSET}", :yellow)
        else
          prepend_to_file SCSS_ASSET, "@use '#{dependency}';\n"
        end
      end

      def scss_dependency
        if gem_loaded?('dartsass-sprockets')
          'active_scaffold'
        elsif gem_loaded?('dartsass-rails')
          'active_scaffold/core'
        end
      end

      def add_to_css_asset
        file = CSS_ASSETS.find do |path|
          File.exist?(path) && File.binread(path).match?(/\*= require(?:_tree)?\b/)
        end
        unless file
          say_status('missing', 'no Dart Sass entrypoint or Sprockets stylesheet manifest found', :red)
          return
        end

        original_css = File.binread(file)
        if original_css.match?(/\*= require +active_scaffold(?:\s|$)/)
          say_status('skipped', "add ActiveScaffold to #{file}", :yellow)
        else
          insert_into_file file, " *= require active_scaffold\n", after: /^[ \t]*\*= require(?:_tree)?\b.*\n/
        end
      end

      def propshaft?
        asset_pipeline == :propshaft
      end

      def sprockets?
        asset_pipeline == :sprockets
      end

      def asset_pipeline
        return :propshaft if propshaft_active?
        return :sprockets if sprockets_active?
        return :propshaft if gem_loaded?('propshaft')

        :sprockets if gem_loaded?('sprockets-rails')
      end

      def propshaft_active?
        defined?(Propshaft::Assembly) && Rails.application.respond_to?(:assets) &&
          Rails.application.assets.is_a?(Propshaft::Assembly)
      end

      def sprockets_active?
        defined?(Sprockets::Environment) && Rails.application.respond_to?(:assets) &&
          Rails.application.assets.is_a?(Sprockets::Environment)
      end

      def jquery?
        Object.const_defined?(:Jquery)
      end

      def gem_loaded?(name)
        Gem.loaded_specs.key?(name)
      end
    end
  end
end
