require 'test/unit'
require 'rubygems'
require 'active_support'

%w(../lib/delete_file_column.rb mock_model.rb).each do |file|
  require File.expand_path(File.join(File.dirname(__FILE__), file))
end
