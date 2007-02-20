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

available_themes = Dir[File.join(directory, 'themes', '*')].collect { |d| File.basename d }
[ :stylesheets, :javascripts, :images].each do |asset_type|
  path = "/public/#{asset_type}/active_scaffold"
  copy_files(path, path, directory)

  available_themes.each do |theme|
    source = "/themes/#{theme}/#{asset_type}/"
    destination = "/public/#{asset_type}/active_scaffold/#{theme}"
    copy_files(source, destination, directory)
  end
end