require 'test/unit'

require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))

require 'rubygems'
require 'action_controller'
require 'action_view'
require 'active_support'
require 'active_record'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib/'
require File.dirname(__FILE__) + '/../environment.rb'
require File.dirname(__FILE__) + '/model_stub'

ModelStub.connection.instance_eval do
  def quote_column_name(name)
    name
  end
end