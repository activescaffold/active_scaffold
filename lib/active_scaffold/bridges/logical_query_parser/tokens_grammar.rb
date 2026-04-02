# frozen_string_literal: true

Treetop.load File.expand_path('tokens_grammar.treetop', __dir__)

class ActiveScaffold::Bridges::LogicalQueryParser
  module TokensGrammar
    class Parser
      def initialize(operator = 'AND')
        @operator = operator
      end

      def parse(*, **)
        super.tap do |node|
          node.instance_variable_set(:@literal_operator, @operator)
        end
      end
    end

    module ExpNode
      def to_sql(params = {})
        params[:_sql] ||= +''
        params[:literal_operator] ||= @literal_operator || 'AND'
        exp.to_sql(params)
      end
    end

    module LiteralExpNode
      def to_sql(params)
        word.to_sql(params)
        params[:_sql] << " #{params[:literal_operator]} "
        exp.to_sql(params)
      end
    end

    module WordNode
      def to_sql(params)
        text = LogicalQueryParser.unquote(word.text_value)

        sql = build_arel(params, :matches, text).reduce(:or).to_sql
        sql = "(#{sql})" if sql[0] != '(' && sql[-1] != ')'
        params[:_sql] << sql
      end

      private

      def build_arel(params, operator, text)
        if params[:columns].is_a?(Hash)
          build_arel_from_hash(params[:model], params[:columns], operator, text)
        else
          build_arel_from_columns(params[:model], params[:columns], operator, text)
        end
      end

      def build_arel_from_columns(klass, columns, operator, text)
        columns.map { |column| klass.arel_table[column].send(operator, Arel.sql(klass.connection.quote("%#{text}%"))) }
      end

      def build_arel_from_hash(klass, hash, operator, text)
        hash.flat_map do |assoc_klass, columns|
          build_arel_from_columns(assoc_klass, columns, operator, text)
        end
      end
    end
  end
end
