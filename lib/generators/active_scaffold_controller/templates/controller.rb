class <%= controller_class_name %>Controller < ApplicationController
  active_scaffold :<%= class_name.demodulize %> do |conf|
  end
end 