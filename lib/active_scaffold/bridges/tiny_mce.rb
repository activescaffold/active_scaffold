class ActiveScaffold::Bridges::TinyMce < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), "tiny_mce/helpers.rb")
  end

  def self.install?
    true # TODO check if tinymce-rails ist installed
  end
end
