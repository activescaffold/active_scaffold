# frozen_string_literal: true

require 'method_source'

class ActiveScaffold::Bridges::LogicalQueryParser
  class KeywordQueryParser
    LogicalQueryParser.singleton_methods.each do |method_name|
      method = LogicalQueryParser.method(method_name)
      define_method(method_name, &method)
    end

    # Define a new method with the same source code
    class_eval <<-RUBY
      #{LogicalQueryParser.method(:search).source}
    RUBY

    def initialize(operator)
      @operator = operator
    end

    def new
      ActiveScaffold::Bridges::LogicalQueryParser::TokensGrammar::Parser.new(@operator)
    end
  end
end
