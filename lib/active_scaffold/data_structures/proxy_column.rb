# frozen_string_literal: true

module ActiveScaffold::DataStructures
  class ProxyColumn
    COPY_VARS = %i[@list_ui @list_ui_options @show_ui @show_ui_options @search_ui @search_ui_options @search_joins].freeze
    def initialize(column)
      @column = column
      # without override_or_delegate, the methods won't use column's values if they are set
      # with override_or_delegate, if they had no value, they won't return overrided form_ui
      # the easier way is copying variables to proxy object
      (column.instance_variables & COPY_VARS).each do |var|
        instance_variable_set(var, column.instance_variable_get(var))
      end
    end

    def self.attr_reader(*names)
      names.each do |name|
        define_method name do
          instance_variable_defined?("@#{name}") ? instance_variable_get("@#{name}") : @column.send(name)
        end
      end
    end

    def self.attr_accessor(*names)
      attr_reader *names
      attr_writer *names
    end

    def self.override_or_delegate(*names)
      location = caller_locations(1, 1).first
      file, line = location.path, location.lineno
      method_def = []

      names.each do |name|
        method_def <<
          "def #{name}(...)
            instance_variable_defined?(\"@#{name.to_s.gsub(/\?$/, '')}\") ? super : @column.send(\"#{name}\", ...)
          end"
      end

      module_eval method_def.join(';'), file, line
      names
    end

    include Column::ProxyableMethods

    def method_missing(name, *args, &block)
      if respond_to_missing?(name, true)
        @column.send(name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_all = false)
      !name.match?(/[!=]$/) && @column.respond_to?(name, include_all) || super
    end

    def params=(value)
      @params = Set.new(*value)
    end
    attr_reader :params, :options

    override_or_delegate :required?, :label, :description, :placeholder, :sort, :associated_number?,
                         :show_blank_record?, :number?, :search_sql, :link
    delegate :==, to: :@column

    def is_a?(klass)
      super || @column.is_a?(klass)
    end
  end
end
