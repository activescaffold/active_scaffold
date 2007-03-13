class ActiveRecord::Base

  def to_label
    [:name, :label, :title, :to_s].each do |attribute|
      return send(attribute) if respond_to? attribute
    end
  end

  def associated_valid?
    with_instantiated_associated {|a| a.valid? and a.associated_valid?}
  end

  def save_associated
    with_instantiated_associated {|a| a.save and a.save_associated}
  end

  def save_associated!
    self.save_associated || raise(RecordNotSaved)
  end

  private

  # yields every associated object that has been instantiated (and therefore possibly changed).
  # returns true if all yields return true. returns false otherwise.
  def with_instantiated_associated
    self.class.reflect_on_all_associations.all? do |association|
      if associated = instance_variable_get("@#{association.name}")
        case association.macro
          when :belongs_to, :has_one
          yield associated

          when :has_many, :has_and_belongs_to_many
          associated.all? {|r| yield r}
        end
      else
        true
      end
    end
  end
end