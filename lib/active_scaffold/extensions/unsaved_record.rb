# a simple (manual) unsaved? flag and method. at least it automatically reverts after a save!
module ActiveScaffold::UnsavedRecord
  # acts like a dirty? flag, manually thrown during update_record_from_params.
  def unsaved=(val)
    @unsaved = val ? true : false
  end

  # whether the unsaved? flag has been thrown
  def unsaved?
    @unsaved
  end

  # automatically unsets the unsaved flag
  def save(**)
    super.tap { self.unsaved = false }
  end

  def keeping_errors
    old_errors = errors.dup if errors.present?
    result = yield
    old_errors&.each do |attr|
      old_errors[attr].each { |msg| errors.add(attr, msg) unless errors.added?(attr, msg) }
    end
    result && old_errors.blank?
  end
end
ActiveRecord::Base.class_eval { include ActiveScaffold::UnsavedRecord }
