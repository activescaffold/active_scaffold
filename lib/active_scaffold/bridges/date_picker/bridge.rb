ActiveScaffold::Bridges.bridge "DatePicker" do
  install do
    require File.join(File.dirname(__FILE__), "lib/datepicker_bridge.rb") if ActiveScaffold.js_framework == :jquery
  end

  
  install? do
    true
  end
end
