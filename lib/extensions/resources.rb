module ActionController
  module Resources
    class Resource
      # by overwriting the attr_reader :options, we can parse out a special :active_scaffold flag just-in-time.
      def options
        if @options.delete :active_scaffold
          logger.info "ActiveScaffold: extending RESTful routes for #{@plural}"
          @options[:collection] ||= {}
          @options[:collection].merge! :show_search => :get, :update_table => :get, :edit_associated => :get, :list => :get
          @options[:member] ||= {}
          @options[:member].merge! :row => :get, :nested => :get, :edit_associated => :get, :add_association => :get
        end
        @options
      end

      def logger
        ActionController::Base::logger
      end
    end
  end
end