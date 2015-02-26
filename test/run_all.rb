test_folders = %w(bridges config data_structures extensions misc)

all_tests = test_folders.inject([]) do |folder, output|
  output << Dir[File.join(File.dirname(__FILE__), "#{folder}/**/*.rb")]
end
all_tests.each { |filename| require filename }
