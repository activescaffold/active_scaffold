# frozen_string_literal: true

require 'method_source'

class ActiveScaffold::Bridges::LogicalQueryParser
  class KeywordQueryParser
    LogicalQueryParser.singleton_methods.each do |method_name|
      method = LogicalQueryParser.method(method_name)
      define_method(method_name, &method)
    end

    # Copy search method from LogicalQueryParser
    class_eval(LogicalQueryParser.method(:search).source, __FILE__, __LINE__)

    def initialize(operator)
      @operator = operator
    end

    def new
      ActiveScaffold::Bridges::LogicalQueryParser::TokensGrammar::Parser.new(@operator)
    end
  end
end
