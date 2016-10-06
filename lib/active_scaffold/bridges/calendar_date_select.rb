class ActiveScaffold::Bridges::CalendarDateSelect < ActiveScaffold::DataStructures::Bridge
  def self.install
    # check to see if the old bridge was installed.  If so, warn them
    # we can detect this by checking to see if the bridge was installed before calling this code

    if ActiveScaffold::Config::Core.method_defined?(:initialize_with_calendar_date_select)
      raise "We've detected that you have active_scaffold_calendar_date_select_bridge installed.  This plugin has been moved to core.  Please remove active_scaffold_calendar_date_select_bridge to prevent any conflicts"
    end

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
