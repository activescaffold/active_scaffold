class ActiveScaffold::Bridges::TinyMce < ActiveScaffold::DataStructures::Bridge
  autoload :Helpers, 'active_scaffold/bridges/tiny_mce/helpers.rb'
  def self.install
    ActionView::Base.class_eval { include ActiveScaffold::Bridges::TinyMce::Helpers }
  end

  def self.install?
    Object.const_defined? 'TinyMCE'
  end

  def self.javascripts
    case ActiveScaffold.js_framework
    when :jquery
      ['tinymce-jquery', 'jquery/tiny_mce_bridge']
    when :prototype
      ['tinymce', 'prototype/tiny_mce_bridge']
    end
  end
end
