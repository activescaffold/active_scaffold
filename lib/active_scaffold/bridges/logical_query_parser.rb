# frozen_string_literal: true

class ActiveScaffold::Bridges::LogicalQueryParser < ActiveScaffold::DataStructures::Bridge
  autoload :TokensGrammar, 'active_scaffold/bridges/logical_query_parser/tokens_grammar'
  autoload :KeywordQueryParser, 'active_scaffold/bridges/logical_query_parser/keyword_query_parser'

  def self.install
    ActiveScaffold::Finder.const_set :LOGICAL_COMPARATORS, %w[all_tokens any_token logical].freeze
  end
end
