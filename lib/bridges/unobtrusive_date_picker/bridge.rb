ActiveScaffold.bridge "UnobtrusiveDatePicker" do
  install do
    require File.join(File.dirname(__FILE__), "lib/unobtrusive_date_picker_bridge.rb")
    require File.join(File.dirname(__FILE__), "lib/form_ui.rb")
    require File.join(File.dirname(__FILE__), "lib/view_helpers.rb")
  end
end
