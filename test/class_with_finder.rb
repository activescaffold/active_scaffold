require 'active_scaffold_config_mock'

class ClassWithFinder
  include ActiveScaffoldConfigMock
  include ActiveScaffold::Finder

  def active_scaffold_config
    self.class.active_scaffold_config
  end

  def conditions_for_collection; end

  def conditions_from_params; end

  def conditions_from_constraints; end

  def active_scaffold_embedded_params
    {}
  end

  def params_hash(value)
    value
  end

  def joins_for_collection; end

  def custom_finder_options
    {}
  end

  def beginning_of_chain
    active_scaffold_config.model
  end

  def conditional_get_support?; end

  def params; {}; end

  def grouped_search?
    false
  end
end
