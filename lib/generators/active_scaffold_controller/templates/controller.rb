class <%= controller_class_name %>Controller < ApplicationController
  active_scaffold :<%= class_name.demodulize.underscore %> do |conf|
  end
end 