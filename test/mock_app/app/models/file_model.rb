class FileModel < ActiveScaffold::Tableless
  column :name, :string
  column :person_id, :integer
  self.primary_key = :name

  belongs_to :person

  def self.find_all(relation)
    relation.conditions&.each&.with_index do |condition, i|
      person_id =
        case condition
        when Hash
          condition[:person_id]
        when Arel::Nodes::Equality
          if condition.left.name.to_sym == :person_id
            relation.bind_values[i].present? ? relation.bind_values[i][1] : condition.right.first
          end
        end
      return [new(person_id: person_id)] if person_id
    end
    []
  end

  def self.find_one(id, relation)
    nil
  end

  def destroy
    true
  end
end
