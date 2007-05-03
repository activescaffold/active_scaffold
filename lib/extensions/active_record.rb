# the ever-useful to_label method
class ActiveRecord::Base
  def to_label
    [:name, :label, :title, :to_s].each do |attribute|
      return send(attribute) if respond_to?(attribute) and send(attribute).is_a?(String)
    end
  end
end

# a simple (manual) unsaved? flag and method. at least it automatically reverts after a save!
class ActiveRecord::Base
  # acts like a dirty? flag, manually thrown during update_record_from_params.
  def unsaved=(val)
    @unsaved = (val) ? true : false
  end

  # whether the unsaved? flag has been thrown
  def unsaved?
    @unsaved
  end

  # automatically unsets the unsaved flag
  def save_with_unsaved_flag(*args)
    result = save_without_unsaved_flag(*args)
    self.unsaved = false
    return result
  end
  alias_method_chain :save, :unsaved_flag
end

# save and validation support for associations.
class ActiveRecord::Base
  def associated_valid?
    # using [].all? syntax to avoid a short-circuit
    with_unsaved_associated { |a| [a.valid?, a.associated_valid?].all? {|v| v == true} }
  end

  def save_associated
    with_unsaved_associated { |a| a.save and a.save_associated }
  end

  def save_associated!
    save_associated or raise(ActiveRecord::RecordNotSaved)
  end

  def no_errors_in_associated?
    with_unsaved_associated {|a| a.errors.count == 0 and a.no_errors_in_associated?}
  end

  protected

  # Provide an override to allow the model to restrict which associations are considered
  # by ActiveScaffolds update mechanism. This allows the model to restrict things like
  # Acts-As-Versioned versions associations being traversed.
  #
  # By defining the method :scaffold_update_nofollow returning an array of associations
  # these associations will not be traversed.
  # By defining the method :scaffold_update_follow returning an array of associations,
  # only those associations will be traversed.
  #
  # Otherwise the default behaviour of traversing all associations will be preserved.
  def associations_for_update
    if self.respond_to?( :scaffold_update_nofollow )
      self.class.reflect_on_all_associations.reject { |association| self.scaffold_update_nofollow.include?( association.name ) }
    elsif self.respond_to?( :scaffold_update_follow )
      self.class.reflect_on_all_associations.select { |association| self.scaffold_update_follow.include?( association.name ) }
    else
      self.class.reflect_on_all_associations
    end
  end

  private

  # yields every associated object that has been instantiated and is flagged as unsaved.
  # returns false if any yield returns false.
  # returns true otherwise, even when none of the associations have been instantiated. build wrapper methods accordingly.
  def with_unsaved_associated
    associations_for_update.all? do |association|
      association_proxy = instance_variable_get("@#{association.name}")
      if association_proxy
        records = association_proxy
        records = [records] unless records.is_a? Array # convert singular associations into collections for ease of use
        records.select {|r| r.unsaved? and not r.readonly?}.all? {|r| yield r} # must use select instead of find_all, which Rails overrides on association proxies for db access
      else
        true
      end
    end
  end
end