class ClassWithFinder
  include ActiveScaffold::Finder
  def conditions_for_collection; end

  def conditions_from_params; end

  def conditions_from_constraints; end

  def joins_for_collection; end

  def custom_finder_options
    {}
  end

  def beginning_of_chain
    active_scaffold_config.model
  end

  def conditional_get_support?; end

  def params; {}; end
end
