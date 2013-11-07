<% if namespaced? -%>
require_dependency "<%= namespaced_file_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  active_scaffold :"<%= class_name.underscore %>" do |conf|
  end
end
<% end -%>
