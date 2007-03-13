class ModelStub < ActiveRecord::Base
  abstract_class = true
  has_one :other_model, :class_name => 'ModelStub'
  has_many :other_models, :class_name => 'ModelStub'
  attr_accessor :a, :b, :c, :d

  def other_model=(val)
    @other_model = val
  end
  def other_model
    @other_model || nil
  end

  def other_models=(val)
    @other_models = val
  end
  def other_models
    @other_models || []
  end

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
