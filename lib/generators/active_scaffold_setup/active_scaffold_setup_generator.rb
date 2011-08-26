module Rails
  module Generators
    class ActiveScaffoldSetupGenerator < Rails::Generators::Base #metagenerator
      argument :js_lib, :type => :string, :default => 'prototype', :desc => 'js_lib for activescaffold (prototype|jquery)' 
      
      def self.source_root
         @source_root ||= File.join(File.dirname(__FILE__), 'templates')
      end

      def install_plugins
        if defined?(ACTIVE_SCAFFOLD_PLUGIN)
          plugin 'verification', :git => 'git://github.com/rails/verification.git'
          plugin 'render_component', :git => 'git://github.com/vhochstein/render_component.git'
        end
        if js_lib == 'prototype'
          get "https://github.com/vhochstein/prototype-ujs/raw/master/src/rails.js", "public/javascripts/rails.js"
        elsif js_lib == 'jquery'
          get "https://github.com/vhochstein/jquery-ujs/raw/master/src/rails.js", "public/javascripts/rails_jquery.js"
          get "https://github.com/vhochstein/jQuery-Timepicker-Addon/raw/master/jquery-ui-timepicker-addon.js", "public/javascripts/jquery-ui-timepicker-addon.js"
        end
      end
      
      def configure_active_scaffold
        return unless js_lib == 'jquery'
        if defined?(ACTIVE_SCAFFOLD_PLUGIN)
          content = "ActiveSupport.on_load(:active_scaffold) { self.js_framework = :jquery }"
        else
          content = "ActiveScaffold.js_framework = :jquery"
        end
        create_file "config/initializers/active_scaffold.rb", content
      end
      
      def configure_application_layout
        if js_lib == 'prototype'
          inject_into_file "app/views/layouts/application.html.erb", 
                    "  <%= active_scaffold_includes %>\n",
                    :after => "<%= javascript_include_tag :defaults %>\n"
        elsif js_lib == 'jquery'
          inject_into_file "app/views/layouts/application.html.erb", 
"  <%= stylesheet_link_tag 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.9/themes/ui-lightness/jquery-ui.css' %>
  <%= javascript_include_tag 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.js' %>
  <%= javascript_include_tag 'rails_jquery.js' %>
  <%= javascript_include_tag 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.9/jquery-ui.js' %>
  <%= javascript_include_tag 'jquery-ui-timepicker-addon.js' %>
  <%= javascript_include_tag 'application.js' %>
  <%= active_scaffold_includes %>\n",
                   :after => "<%= javascript_include_tag :defaults %>\n"
           
          inject_into_file "config/locales/en.yml",
"  time:
    formats:
      default: \"%a, %d %b %Y %H:%M:%S\"",                  
                   :after => "hello: \"Hello world\"\n"
          gsub_file 'app/views/layouts/application.html.erb', /<%= javascript_include_tag :defaults/, '<%# javascript_include_tag :defaults'
        end
      end     
    end
  end
end