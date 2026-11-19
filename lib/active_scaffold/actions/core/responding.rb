# frozen_string_literal: true

module ActiveScaffold::Actions
  module Core
    module Responding
      class AuthorizedApiResponse
        def initialize(response_object, columns_names, config)
          @response_object = response_object
          @columns_names = columns_names
          @config = config
        end

        def to_json(options = {})
          serialized_response(:as_json).to_json(options)
        end

        def to_xml(options = {})
          return serialized_response(:to_xml, options) unless collection?

          xml_options = options.dup
          records = response_records
          if records.present? && records.all?(records.first.class)
            record_name = ActiveSupport::Inflector.underscore(records.first.class.name).tr('/', '_')
            xml_options[:root] ||= ActiveSupport::Inflector.pluralize(record_name)
          end
          serialized_response(:serializable_hash).to_xml(xml_options)
        end

        private

        def serialized_response(method, options = {})
          if collection?
            response_records.map do |record|
              record.public_send(method, options.merge(serialization_options(record)))
            end
          else
            @response_object.public_send(method, options.merge(serialization_options(@response_object)))
          end
        end

        def collection?
          @response_object.respond_to?(:to_ary)
        end

        def response_records
          @response_records ||= @response_object.to_ary
        end

        def serialization_options(record)
          columns_names =
            if record.respond_to?(:authorized_for?)
              @columns_names.select do |column_name|
                record.authorized_for?(crud_type: :read, column: column_name)
              end
            else
              @columns_names
            end
          {
            only: columns_names + [@config.model.primary_key],
            include: association_columns(columns_names),
            methods: virtual_columns(columns_names)
          }
        end

        def virtual_columns(columns_names)
          columns_names.reject do |column_name|
            @config._columns_hash[column_name.to_s] || @config.columns[column_name]&.association
          end
        end

        def association_columns(columns_names)
          columns_names.select { |column_name| @config.columns[column_name]&.association }
        end
      end

      protected

      def set_vary_accept_header
        response.set_header 'vary', 'Accept'
      end

      def default_formats
        %i[html js json xml]
      end

      # Returns true if the client accepts one of the MIME types passed to it
      # ex: accepts? :html, :xml
      def accepts?(*types)
        request.accepts.compact.each do |priority|
          # Because IE always sends */* in the accepts header and we assume
          # that if you really wanted XML or something else you would say so
          # explicitly, we will assume */* to only ask for :html
          return types.include?(:html) if priority == Mime::ALL

          return true if types.include?(priority.to_sym)
        end
        false
      end

      def response_status
        if successful?
          action_name == 'create' ? 201 : 200
        else
          422
        end
      end

      # API response object that will be converted to XML/JSON using to_xxx
      def response_object
        @response_object ||= successful? ? (@record || @records) : @record.errors
      end

      def response_to_api(format, columns_names, options = {})
        set_api_pagination_headers
        response =
          if successful?
            AuthorizedApiResponse.new(response_object, columns_names, active_scaffold_config)
          else
            response_object
          end
        render(options.reverse_merge(format => response, status: response_status))
      end

      def set_api_pagination_headers
        return unless @page && active_scaffold_config.list.api_pagination
        return if @page.pager.infinite?

        response.set_header 'X-Total-Count', @page.pager.count.to_s
        response.set_header 'X-Total-Pages', @page.pager.number_of_pages.to_s
      end

      # Success is the existence of one or more model objects. Most actions
      # circumvent this method by setting @success directly.
      def successful?
        @successful.nil? || @successful
      end

      def successful=(val)
        @successful = val ? true : false
      end

      # Redirect to the main page for Javascript degradation. Override when ActiveScaffold is used as a component on
      # another controller's page.
      def return_to_main
        options = main_path_to_return
        # use url_for in case main_path_to_return returns Hash with status param,
        # which would be interpreted as status option to redirect_to instead of url param
        redirect_to options.is_a?(Hash) ? url_for(options) : options
      end

      def objects_for_etag
        @last_modified ||= @record.updated_at
        [@record, ('xhr' if request.xhr?)]
      end

      def view_stale?
        objects = objects_for_etag
        if objects.is_a?(Array)
          args = {etag: objects.to_a}
          args[:last_modified] = @last_modified if @last_modified
        elsif objects.is_a?(Hash)
          args = {last_modified: @last_modified}.merge(objects)
        else
          args = objects
        end
        stale?(args)
      end

      def conditional_get_support?
        request.get? && active_scaffold_config.conditional_get_support
      end

      def virtual_columns(columns)
        columns.reject do |col|
          active_scaffold_config._columns_hash[col.to_s] || active_scaffold_config.columns[col]&.association
        end
      end

      def association_columns(columns)
        columns.select { |col| active_scaffold_config.columns[col]&.association }
      end

      private

      def respond_to_action(action, formats = action_formats)
        return unless !conditional_get_support? || view_stale?

        respond_to do |type|
          formats.each do |format|
            type.send(format) do
              method_name = respond_method_for(action, format)
              send(method_name) if method_name
            end
          end
        end
      end

      def respond_method_for(action, format)
        if format == :html && params[:iframe] == 'true'
          method_name = "#{action}_respond_on_iframe"
          return method_name if respond_to?(method_name, true)
        end
        method_name = "#{action}_respond_to_#{format}"
        method_name if respond_to?(method_name, true)
      end

      def action_formats
        @action_formats ||=
          if respond_to? :"#{action_name}_formats", true
            send(:"#{action_name}_formats")
          else
            (default_formats + active_scaffold_config.formats).uniq
          end
      end
    end
  end
end
