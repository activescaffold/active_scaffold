require 'minitest/autorun'

%w[../file_column_helpers.rb mock_model.rb].each do |file|
  require File.expand_path(File.join(File.dirname(__FILE__), file))
end
