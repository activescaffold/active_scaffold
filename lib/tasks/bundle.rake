# frozen_string_literal: true

namespace :bundle do
  desc 'Run bundle lock for all Gemfiles in the gemfiles directory'
  task :lock_all do
    gemfiles_dir = File.join(Dir.pwd, 'gemfiles')

    unless Dir.exist?(gemfiles_dir)
      abort "Error: gemfiles directory not found at #{gemfiles_dir}"
    end

    gemfiles = Dir.glob(File.join(gemfiles_dir, 'Gemfile*')).reject do |file|
      file.end_with?('.lock') || File.directory?(file)
    end

    gemfiles.each do |gemfile|
      puts "Locking #{File.basename(gemfile)}..."
      system("bundle lock --gemfile='#{gemfile}'")
    end

    puts 'Done!'
  end
end
