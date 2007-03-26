##
## Copy over asset files (javascript/css/images) from the plugin directory to public/
##

def copy_files(source_path, destination_path, directory)
  source, destination = File.join(directory, source_path), File.join(RAILS_ROOT, destination_path)
  FileUtils.mkdir(destination) unless File.exist?(destination)
  FileUtils.cp_r(Dir.glob(source+'/*.*'), destination)
end

directory = File.dirname(__FILE__)

copy_files("/public", "/public", directory)

available_frontends = Dir[File.join(directory, 'frontends', '*')].collect { |d| File.basename d }
[ :stylesheets, :javascripts, :images].each do |asset_type|
  path = "/public/#{asset_type}/active_scaffold"
  copy_files(path, path, directory)

  available_frontends.each do |frontend|
    source = "/frontends/#{frontend}/#{asset_type}/"
    destination = "/public/#{asset_type}/active_scaffold/#{frontend}"
    copy_files(source, destination, directory)
  end
end

##
## Install a very simple application.rhtml layout, if none exists yet
##
layout_dir = File.join(RAILS_ROOT, 'app', 'views', 'layouts')
FileUtils.cp(File.join(directory, 'frontends', 'application.rhtml'), layout_dir) unless File.exists?(File.join(layout_dir, 'application.rhtml'))