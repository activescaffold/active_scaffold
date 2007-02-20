class ModelStub < ActiveRecord::Base
  abstract_class = true
  has_one :other_model

  def self.columns
    @columns ||= [
      ActiveRecord::ConnectionAdapters::Column.new(:a, ''),
      ActiveRecord::ConnectionAdapters::Column.new(:b, ''),
      ActiveRecord::ConnectionAdapters::Column.new(:c, ''),
      ActiveRecord::ConnectionAdapters::Column.new(:d, '')
    ]
  end

  def self.columns_hash
    @columns_hash ||= columns.inject({}) { |hash, column| hash[column.name.to_s] = column; hash }
  end

  # column-level security methods, used for testing
  def self.a_authorized_for_bar?(user)
    true
  end
  def self.b_authorized?(user)
    false
  end
end