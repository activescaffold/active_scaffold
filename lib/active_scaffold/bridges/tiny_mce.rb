# frozen_string_literal: true

class ActiveScaffold::Bridges::TinyMce < ActiveScaffold::DataStructures::Bridge
  autoload :Helpers, 'active_scaffold/bridges/tiny_mce/helpers.rb'
  def self.install
    ActionView::Base.class_eval { include ActiveScaffold::Bridges::TinyMce::Helpers }
  end

  def self.install?
    Object.const_defined? :TinyMCE
  end

  def self.javascripts
    ['tinymce', 'jquery/tiny_mce_bridge']
  end

  def self.stylesheets
    ['tiny_mce_bridge']
  end
end
