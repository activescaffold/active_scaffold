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
    lib = defined?(Sprockets) ? ['tinymce'] : ['tinymce/tinymce', 'tinymce/rails']
    lib << 'active_scaffold/tiny_mce_bridge'
  end

  def self.javascript_tags
    :tinymce_preinit unless defined?(Sprockets)
  end

  def self.stylesheets
    ['tiny_mce_bridge']
  end
end
