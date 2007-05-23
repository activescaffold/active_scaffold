# the ever-useful to_label method
class ActiveRecord::Base
  def to_label
    [:name, :label, :title, :to_s].each do |attribute|
      return send(attribute) if respond_to?(attribute) and send(attribute).is_a?(String)
    end
  end
end
