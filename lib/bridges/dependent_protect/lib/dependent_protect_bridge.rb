module DependentProtectSecurity
  def self.included(base)
    base.class_inheritable_accessor :dependent_associations
  end
  protected
  def authorized_for_delete?
    self.class.dependent_associations ||= self.class.reflect_on_all_associations.select {|assoc| assoc.options[:dependent] == :protect}
    self.class.dependent_associations.all? {|assoc| self.send(assoc.name).blank?}
  end
end
ActiveRecord::Base.class_eval { include DependentProtectSecurity }
