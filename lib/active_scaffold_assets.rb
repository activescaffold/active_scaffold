class ActiveScaffoldAssets

  def self.copy_to_public(from, options = {})
    unless defined?(ACTIVE_SCAFFOLD_INSTALL_ASSETS) && ACTIVE_SCAFFOLD_INSTALL_ASSETS == false
      copy_files("/public", "/public", from)
      available_frontends = Dir[File.join(from, 'frontends', '*')].collect { |d| File.basename d }
      [:stylesheets, :javascripts, :images].each do |asset_type|
        copy_asset_type(from, available_frontends, asset_type, options)
      end
    end
  end

protected

  def self.copy_asset_type(from, available_frontends, asset_type, options = {})
    path = "/public/#{asset_type}/active_scaffold"
    copy_files(path, path, from)

    File.open(File.join(Rails.root, path, 'DO_NOT_EDIT'), 'w') do |f|
      f.puts "Any changes made to files in sub-folders will be lost."
      f.puts "See http://activescaffold.com/tutorials/faq#custom-css."
    end

    available_frontends.each do |frontend|
      if asset_type == :javascripts
        file_mask = '*.js'
        source = "/frontends/#{frontend}/#{asset_type}/#{ActiveScaffold.js_framework}"
      else
        file_mask = '*.*'
        source = "/frontends/#{frontend}/#{asset_type}"
      end
      destination = "/public/#{asset_type}/active_scaffold/#{frontend}"
      copy_files(source, destination, from, file_mask, options)
    end
  end

  def self.copy_files(source_path, destination_path, directory, file_mask = '*.*', options = {})
    source, destination = File.join(directory, source_path), File.join(Rails.root, destination_path)
    FileUtils.mkdir_p(destination) unless File.exist?(destination)
    Dir.glob('*.so')

    FileUtils.rm Dir.glob("#{destination}/*") if options[:clean_up_destination]
    FileUtils.cp_r(Dir.glob("#{source}/#{file_mask}"), destination)
  end
end