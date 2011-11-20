class ActiveScaffold::Bridges::TinyMce < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), "tiny_mce/helpers.rb")
  end

  def self.install?
    Object.const_defined? "TinyMCE"
  end
 
  def self.javascripts
    if ActiveScaffold.js_framework == :jquery
      ['tinymce-jquery', 'jquery/tiny_mce_bridge']
    else
      ['tinymce', 'prototype/tiny_mce_bridge']
    end
  end
end
