class ActiveScaffold::Bridges::CalendarDateSelect < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'calendar_date_select/as_cds_bridge.rb')
  end

  def self.install?
    super && ActiveScaffold.js_framework == :prototype
  end

  def self.stylesheets
    calendar_date_select_stylesheets
  end

  def self.javascripts
    calendar_date_select_javascripts
  end
end
