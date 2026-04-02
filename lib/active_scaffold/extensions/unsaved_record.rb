# frozen_string_literal: true

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
    old_errors&.each do |e|
      if e.is_a?(String) || e.is_a?(Symbol)
        # Rails <6.1 errors API.
        old_errors[e].each { |msg| errors.add(e, msg) unless errors.added?(e, msg) }
      else
        # Rails >=6.1 errors API (https://code.lulalala.com/2020/0531-1013.html).
        errors.add(e.attribute, e.message) unless errors.added?(e.attribute, e.message)
      end
    end
    result && old_errors.blank?
  end
end
ActiveRecord::Base.class_eval { include ActiveScaffold::UnsavedRecord }
