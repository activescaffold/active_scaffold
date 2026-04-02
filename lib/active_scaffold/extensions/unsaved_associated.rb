# frozen_string_literal: true

# save and validation support for associations.
class ActiveRecord::Base
  def associated_valid?(path = ::Set.new)
    return true if path.include?(self) # prevent recursion (if associated and parent are new records)

    path << self
    # using [].all? syntax to avoid a short-circuit
    # errors to associated record can be added by update_record_from_params when association fails to set and ActiveRecord::RecordNotSaved is raised
    with_unsaved_associated { |a| [a.keeping_errors { a.valid? }, a.associated_valid?(path)].all? }.all?
  end

  def save_associated # rubocop:disable Naming/PredicateMethod
    with_unsaved_associated { |a| a.save && a.save_associated }.all?
  end

  def save_associated!
    save_associated || raise(ActiveRecord::RecordNotSaved, "Fail saving associations for #{inspect}")
  end

  def no_errors_in_associated?
    with_unsaved_associated { |a| a.errors.none? && a.no_errors_in_associated? }.all?
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
    if respond_to?(:scaffold_update_nofollow)
      self.class.reflect_on_all_associations.reject { |association| scaffold_update_nofollow.include?(association.name) }
    elsif respond_to?(:scaffold_update_follow)
      self.class.reflect_on_all_associations.select { |association| scaffold_update_follow.include?(association.name) }
    else
      self.class.reflect_on_all_associations
    end
  end

  private

  # yields every associated object that has been instantiated and is flagged as unsaved.
  # returns false if any yield returns false.
  # returns true otherwise, even when none of the associations have been instantiated. build wrapper methods accordingly.
  def with_unsaved_associated(&block)
    associations_for_update.flat_map do |assoc|
      association_proxy = association(assoc.name)
      if association_proxy.target.present?
        records = association_proxy.target
        records = [records] unless records.is_a? Array # convert singular associations into collections for ease of use
        # must use select instead of find_all, which Rails overrides on association proxies for db access
        records.select { |r| r.unsaved? && !r.readonly? }.map(&block)
      else
        true
      end
    end
  end
end
