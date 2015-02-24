class FileModel < ActiveScaffold::Tableless
  column :name, :string
  column :person_id, :integer
  self.primary_key = :name

  belongs_to :person

  def self.find_all(relation)
    []
  end

  def self.find_one(id, relation)
    nil
  end

  def destroy
    true
  end
end
