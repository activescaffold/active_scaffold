# a simple (manual) unsaved? flag and method. at least it automatically reverts after a save!
module ActiveScaffold::UnsavedRecord
  # acts like a dirty? flag, manually thrown during update_record_from_params.
  def unsaved=(val)
    @unsaved = (val) ? true : false
  end

  # whether the unsaved? flag has been thrown
  def unsaved?
    @unsaved
  end

  # automatically unsets the unsaved flag
  def save(*)
    super.tap { self.unsaved = false }
  end
end
ActiveRecord::Base.class_eval { include ActiveScaffold::UnsavedRecord }
