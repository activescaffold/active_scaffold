class ActiveScaffold::Bridges::LogicalQueryParser < ActiveScaffold::DataStructures::Bridge
  def self.install
    require File.join(File.dirname(__FILE__), 'logical_query_parser/tokens_grammar')
    ActiveScaffold::Finder.send(:remove_const, :LOGICAL_COMPARATORS)
    ActiveScaffold::Finder.const_set :LOGICAL_COMPARATORS, %w[all_tokens any_token logical].freeze
  end
end
