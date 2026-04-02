# frozen_string_literal: true

module ActiveScaffold::DataStructures
  module Association
    autoload :Abstract, 'active_scaffold/data_structures/association/abstract.rb'
    autoload :ActiveRecord, 'active_scaffold/data_structures/association/active_record.rb'
    autoload :Mongoid, 'active_scaffold/data_structures/association/mongoid.rb'
    autoload :ActiveMongoid, 'active_scaffold/data_structures/association/active_mongoid.rb'
  end
end
