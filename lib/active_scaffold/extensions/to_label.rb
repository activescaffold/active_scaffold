# frozen_string_literal: true

# the ever-useful to_label method
class ActiveRecord::Base
  def to_label
    to_label_method = ActiveScaffold::Registry.cache :to_label, self.class.name do
      %i[name label title to_s].find { |attribute| respond_to?(attribute) }
    end
    send(to_label_method).to_s if to_label_method
  end
end
